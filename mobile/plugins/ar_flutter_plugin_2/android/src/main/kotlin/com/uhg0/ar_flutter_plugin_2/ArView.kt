package com.uhg0.ar_flutter_plugin_2

import android.app.Activity
import android.content.Context
import android.graphics.Bitmap
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.opengl.Matrix as GLMatrix
import android.util.Log
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.PixelCopy
import android.view.ScaleGestureDetector
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.lifecycle.Lifecycle
import com.google.ar.core.Anchor
import com.google.ar.core.Anchor.CloudAnchorState
import com.google.ar.core.Config
import com.google.ar.core.Frame
import com.google.ar.core.Plane
import com.google.ar.core.Point
import com.google.ar.core.DepthPoint
import com.google.ar.core.InstantPlacementPoint
import com.google.ar.core.Pose
import com.google.ar.core.TrackingState
import com.uhg0.ar_flutter_plugin_2.Serialization.deserializeMatrix4
import com.uhg0.ar_flutter_plugin_2.Serialization.serializeHitResult
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import io.github.sceneview.ar.ARSceneView
import io.github.sceneview.ar.arcore.canHostCloudAnchor
import io.github.sceneview.ar.arcore.fps
import io.github.sceneview.ar.node.AnchorNode
import io.github.sceneview.ar.node.CloudAnchorNode
import io.github.sceneview.ar.node.HitResultNode
import io.github.sceneview.gesture.MoveGestureDetector
import io.github.sceneview.gesture.RotateGestureDetector
import io.github.sceneview.math.Position
import io.github.sceneview.math.Transform
import io.github.sceneview.model.ModelInstance
import io.github.sceneview.node.ModelNode
import io.github.sceneview.node.Node
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import io.github.sceneview.math.Position as ScenePosition
import io.github.sceneview.math.Rotation as SceneRotation
import io.github.sceneview.math.Scale as SceneScale
import io.github.sceneview.texture.ImageTexture
import io.github.sceneview.material.setTexture
import io.github.sceneview.ar.scene.PlaneRenderer
import io.flutter.FlutterInjector
import io.github.sceneview.node.CylinderNode
import io.github.sceneview.math.Direction
import io.github.sceneview.math.Rotation
import io.github.sceneview.math.Scale
import io.github.sceneview.math.colorOf
import io.github.sceneview.loaders.MaterialLoader
import com.google.ar.core.exceptions.SessionPausedException

class ArView(
    context: Context,
    private val activity: Activity,
    private val lifecycle: Lifecycle,
    messenger: BinaryMessenger,
    id: Int,
) : PlatformView {
    private val TAG: String = ArView::class.java.name
    private val viewContext: Context = context
    private var sceneView: ARSceneView
    private val mainScope = CoroutineScope(Dispatchers.Main)
    private var worldOriginNode: Node? = null

    private val rootLayout: ViewGroup = FrameLayout(context)

    private val sessionChannel: MethodChannel = MethodChannel(messenger, "arsession_$id")
    private val objectChannel: MethodChannel = MethodChannel(messenger, "arobjects_$id")
    private val anchorChannel: MethodChannel = MethodChannel(messenger, "aranchors_$id")
    private val nodesMap = mutableMapOf<String, ModelNode>()
    private var planeCount = 0
    private var selectedNode: Node? = null
    private val detectedPlanes = mutableSetOf<Plane>()
    private val anchorNodesMap = mutableMapOf<String, AnchorNode>()
    private var showAnimatedGuide = true
    private var showFeaturePoints = false
    private val pointCloudNodes = mutableListOf<PointCloudNode>()
    private var lastPointCloudTimestamp: Long? = null
    private var lastPointCloudFrame: Frame? = null
    private var pointCloudModelInstances = mutableListOf<ModelInstance>()
    private var handlePans = false  
    private var handleRotation = false
    private var isSessionPaused = false
    private var latestFrame: Frame? = null
    private var measurementAnchor: Anchor? = null
    private var measurementStartScreenX: Float? = null
    private var measurementStartScreenY: Float? = null

    // Cache the most recent stable reticle hit while the user is aiming.
    // START can then lock immediately to a fresh stable world pose instead
    // of waiting for ARCore to rediscover the same surface after the tap.
    private var cachedStableMeasurementPose: Pose? = null
    private var cachedStableMeasurementPoseDistance: Float? = null
    private var cachedStableMeasurementPoseTimeMs: Long = 0L

    private class PointCloudNode(
        modelInstance: ModelInstance,
        var id: Int,
        var confidence: Float,
    ) : ModelNode(modelInstance)

    private val onSessionMethodCall =
        MethodChannel.MethodCallHandler { call, result ->
            when (call.method) {
                "init" -> handleInit(call, result)
                "showPlanes" -> handleShowPlanes(call, result)
                "dispose" -> dispose()
                "getAnchorPose" -> handleGetAnchorPose(call, result)
                "getCenterHitTest" -> handleGetCenterHitTest(result)
                "lockCenterMeasurementAnchor" -> handleLockCenterMeasurementAnchor(result)
                "getMeasurementAnchorPosition" -> handleGetMeasurementAnchorPosition(result)
                "getMeasurementAnchorScreenPosition" -> handleGetMeasurementAnchorScreenPosition(result)
                "getMeasurementVerticalGuideScreenPosition" -> handleGetMeasurementVerticalGuideScreenPosition(result)
                "getNativeHeightRuler" -> handleGetNativeHeightRuler(result)
                "clearMeasurementAnchor" -> handleClearMeasurementAnchor(result)
                "getCameraPose" -> handleGetCameraPose(result)
                "snapshot" -> handleSnapshot(result)
                "disableCamera" -> handleDisableCamera(result)
                "enableCamera" -> handleEnableCamera(result)
                else -> result.notImplemented()
            }
        }
    private fun handleDisableCamera(result: MethodChannel.Result) {
        try {
            isSessionPaused = true
            sceneView.session?.pause()
            result.success(null)
        } catch (e: Exception) {
            result.error("DISABLE_CAMERA_ERROR", e.message, null)
        }
    }
    private fun handleEnableCamera(result: MethodChannel.Result) {
        try {
            isSessionPaused = false
            sceneView.session?.resume()
            result.success(null)
        } catch (e: Exception) {
            result.error("ENABLE_CAMERA_ERROR", e.message, null)
        }
    }
    private val onObjectMethodCall =
        MethodChannel.MethodCallHandler { call, result ->
            when (call.method) {
                "addNode" -> {
                    val nodeData = call.arguments as? Map<String, Any>
                    nodeData?.let {
                        handleAddNode(it, result)
                    } ?: result.error("INVALID_ARGUMENTS", "Node data is required", null)
                }
                "addNodeToPlaneAnchor" -> handleAddNodeToPlaneAnchor(call, result)
                "addNodeToScreenPosition" -> handleAddNodeToScreenPosition(call, result)
                "removeNode" -> {
                    handleRemoveNode(call, result)
                }
                "transformationChanged" -> {
                    handleTransformNode(call, result)
                }
                else -> result.notImplemented()
            }
        }

    private val onAnchorMethodCall =
        MethodChannel.MethodCallHandler { call, result ->
            when (call.method) {
                "addAnchor" -> handleAddAnchor(call, result)
                "removeAnchor" -> {
                    val anchorName = call.argument<String>("name")
                    handleRemoveAnchor(anchorName, result)
                }
                "initGoogleCloudAnchorMode" -> handleInitGoogleCloudAnchorMode(result)
                "uploadAnchor" -> handleUploadAnchor(call, result)
                "downloadAnchor" -> handleDownloadAnchor(call, result)
                else -> result.notImplemented()
            }
        }

    init {
        sceneView = ARSceneView(
            context = viewContext,
            sharedLifecycle = lifecycle,
            sessionConfiguration = { session, config ->
                config.apply {
                    depthMode = Config.DepthMode.DISABLED
                    instantPlacementMode = Config.InstantPlacementMode.LOCAL_Y_UP
                    lightEstimationMode = Config.LightEstimationMode.ENVIRONMENTAL_HDR
                    focusMode = Config.FocusMode.AUTO
                    planeFindingMode = Config.PlaneFindingMode.HORIZONTAL_AND_VERTICAL
                }
            }
        )
        
        rootLayout.addView(sceneView)

        sessionChannel.setMethodCallHandler(onSessionMethodCall)
        objectChannel.setMethodCallHandler(onObjectMethodCall)
        anchorChannel.setMethodCallHandler(onAnchorMethodCall)
    }

    

    private suspend fun buildModelNode(nodeData: Map<String, Any>): ModelNode? {
        var fileLocation = nodeData["uri"] as? String ?: return null
        when (nodeData["type"] as Int) {
                0 -> { // GLTF2 Model from Flutter asset folder
                    // Get path to given Flutter asset
                    val loader = FlutterInjector.instance().flutterLoader()
                    fileLocation = loader.getLookupKeyForAsset(fileLocation)
                }
                1 -> { // GLB Model from the web
                    fileLocation = fileLocation
                }
                2 -> { // fileSystemAppFolderGLB
                    fileLocation = fileLocation
                }
                 3 -> { //fileSystemAppFolderGLTF2
                    val documentsPath = viewContext.getApplicationInfo().dataDir
                    val fileLocation = documentsPath + "/app_flutter/" + nodeData["uri"] as String
                 }
                else -> {
                    return null
                }
        }
        
        if (fileLocation == null) {
            return null
        }
        val transformation = nodeData["transformation"] as? ArrayList<Double>
        if (transformation == null) {
            return null
        }

        return try {
            sceneView.modelLoader.loadModelInstance(fileLocation)?.let { modelInstance ->
                object : ModelNode(
                    modelInstance = modelInstance,
                    scaleToUnits = transformation.first().toFloat(),
                ) {
                    override fun onMove(detector: MoveGestureDetector, e: MotionEvent): Boolean {
                            if (handlePans) {
                            val defaultResult = super.onMove(detector, e)
                            objectChannel.invokeMethod("onPanChange", name)
                            return defaultResult
                            }
                    return false
                    }
                    
                    override fun onMoveBegin(detector: MoveGestureDetector, e: MotionEvent): Boolean {
                        if (handlePans) {
                            val defaultResult = super.onMoveBegin(detector, e)
                            objectChannel.invokeMethod("onPanStart", name)
                            defaultResult
                        } 
                        return false
                    }
                    
                    override fun onMoveEnd(detector: MoveGestureDetector, e: MotionEvent) {
                        if (handlePans) {
                            super.onMoveEnd(detector, e)
                            val transformMap = mapOf(
                                "name" to name,
                                "transform" to transform.toFloatArray().toList()
                            )
                            objectChannel.invokeMethod("onPanEnd", transformMap)
                        }
                    }

                    override fun onRotateBegin(detector: RotateGestureDetector, e: MotionEvent): Boolean {
                        if (handleRotation) {
                            val defaultResult = super.onRotateBegin(detector, e)
                            objectChannel.invokeMethod("onRotationStart", name)
                            return defaultResult
                        }
                        return false
                    }

                    override fun onRotate(detector: RotateGestureDetector, e: MotionEvent): Boolean {
                        if (handleRotation) {
                            val defaultResult = super.onRotate(detector, e)
                            objectChannel.invokeMethod("onRotationChange", name)
                            return defaultResult
                        }
                        return false
                    }

                    override fun onRotateEnd(detector: RotateGestureDetector, e: MotionEvent) {
                        if (handleRotation) {
                            super.onRotateEnd(detector, e)
                            val transformMap = mapOf(
                                "name" to name,
                                "transform" to transform.toFloatArray().toList()
                            )
                            objectChannel.invokeMethod("onRotationEnd", transformMap)
                        }
                    }
                }.apply {
                    isPositionEditable = handlePans
                    isRotationEditable = handleRotation
                    name = nodeData["name"] as? String
                }
            } ?: run {
                null
            }
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    private fun handleAddNodeToPlaneAnchor(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        try {
            val nodeData = call.arguments as? Map<String, Any>
            val dict_node = nodeData?.get("node") as? Map<String, Any>
            val dict_anchor = nodeData?.get("anchor") as? Map<String, Any>
            if (dict_node == null || dict_anchor == null) {
                result.success(false)
                return
            }

            val anchorName = dict_anchor["name"] as? String
            val anchorNode = anchorNodesMap[anchorName]
            if (anchorNode != null) {
                mainScope.launch {
                    try {
                        buildModelNode(dict_node)?.let { node ->
                            anchorNode.addChildNode(node)
                            sceneView.addChildNode(anchorNode)
                            node.name?.let { nodeName ->
                                nodesMap[nodeName] = node
                            }
                            result.success(true)
                        } ?: result.success(false)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
            } else {
                result.success(false)
            }
        } catch (e: Exception) {
            result.success(false)
        }
    }

    private fun handleAddNodeToScreenPosition(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        try {
            val nodeData = call.arguments as? Map<String, Any>
            val screenPosition = call.argument<Map<String, Double>>("screenPosition")

            if (nodeData == null || screenPosition == null) {
                result.error("INVALID_ARGUMENT", "Node data or screen position is null", null)
                return
            }

            mainScope.launch {
                val node = buildModelNode(nodeData) ?: return@launch
                val hitResultNode =
                    HitResultNode(
                        engine = sceneView.engine,
                        xPx = screenPosition["x"]?.toFloat() ?: 0f,
                        yPx = screenPosition["y"]?.toFloat() ?: 0f,
                    ).apply {
                        addChildNode(node)
                    }

                sceneView.addChildNode(hitResultNode)
                result.success(null)
            }
        } catch (e: Exception) {
            result.error("ADD_NODE_TO_SCREEN_ERROR", e.message, null)
        }
    }

    private fun handleInit(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        try {
            val argShowAnimatedGuide = call.argument<Boolean>("showAnimatedGuide") ?: true
            val argShowFeaturePoints = call.argument<Boolean>("showFeaturePoints") ?: false
            val argPlaneDetectionConfig: Int? = call.argument<Int>("planeDetectionConfig")
            val argShowPlanes = call.argument<Boolean>("showPlanes") ?: true
            val customPlaneTexturePath = call.argument<String>("customPlaneTexturePath")
            val showWorldOrigin = call.argument<Boolean>("showWorldOrigin") ?: false
            val handleTaps = call.argument<Boolean>("handleTaps") ?: true
            handlePans = call.argument<Boolean>("handlePans") ?: false
            handleRotation = call.argument<Boolean>("handleRotation") ?: false

            sceneView.session?.let { session ->
                session.configure(session.config.apply {
                    depthMode = when (session.isDepthModeSupported(Config.DepthMode.AUTOMATIC)) {
                        true -> Config.DepthMode.AUTOMATIC
                        else -> Config.DepthMode.DISABLED
                    }
                    instantPlacementMode = Config.InstantPlacementMode.LOCAL_Y_UP
                    planeFindingMode = when (argPlaneDetectionConfig) {
                        1 -> Config.PlaneFindingMode.HORIZONTAL
                        2 -> Config.PlaneFindingMode.VERTICAL
                        3 -> Config.PlaneFindingMode.HORIZONTAL_AND_VERTICAL
                        else -> Config.PlaneFindingMode.HORIZONTAL_AND_VERTICAL
                    }
                })
            }

            handleShowWorldOrigin(showWorldOrigin)
            
            sceneView.apply {
                environment = environmentLoader.createHDREnvironment(
                    assetFileLocation = "environments/evening_meadow_2k.hdr"
                )!!

                planeRenderer.isEnabled = argShowPlanes
                planeRenderer.isVisible = argShowPlanes
                planeRenderer.planeRendererMode = PlaneRenderer.PlaneRendererMode.RENDER_ALL

                onTrackingFailureChanged = { reason ->
                    mainScope.launch {
                        sessionChannel.invokeMethod("onTrackingFailure", reason?.name)
                    }
                }

                if (argShowFeaturePoints == true) {
                    showFeaturePoints = true
                } else {
                    showFeaturePoints = false
                    pointCloudNodes.toList().forEach { removePointCloudNode(it) }
                }

                onFrame = { frameTime ->
                    try {
                        if (!isSessionPaused) {
                            session?.update()?.let { frame ->
                                latestFrame = frame

                                // Pre-fetch a trustworthy measurement depth on every AR frame.
                                // This makes START responsive because Point A does not have to
                                // wait for the next 100 ms Flutter polling cycle to discover a hit.
                                if (
                                    frame.camera.trackingState == TrackingState.TRACKING &&
                                    sceneView.width > 0 &&
                                    sceneView.height > 0
                                ) {
                                    val prefetchHit = findStableMeasurementHit(
                                        frame,
                                        sceneView.width / 2f,
                                        sceneView.height / 2f,
                                    )

                                    if (prefetchHit != null) {
                                        cachedStableMeasurementPose = prefetchHit.hitPose
                                        cachedStableMeasurementPoseDistance = prefetchHit.distance
                                        cachedStableMeasurementPoseTimeMs =
                                            SystemClock.elapsedRealtime()
                                    }
                                }

                                if (showAnimatedGuide) {
                                    frame.getUpdatedTrackables(Plane::class.java).forEach { plane ->
                                        if (plane.trackingState == TrackingState.TRACKING) {
                                            rootLayout.findViewWithTag<View>("hand_motion_layout")?.let { handMotionLayout ->
                                                rootLayout.removeView(handMotionLayout)
                                                showAnimatedGuide = false
                                            }
                                        }
                                    }
                                }

                                if (showFeaturePoints) {
                                    val currentFps = frame.fps(lastPointCloudFrame)
                                    if (currentFps < 10) {
                                        frame.acquirePointCloud()?.let { pointCloud ->
                                            if (pointCloud.timestamp != lastPointCloudTimestamp) {
                                                lastPointCloudFrame = frame
                                                lastPointCloudTimestamp = pointCloud.timestamp

                                                val pointsSize = pointCloud.ids?.limit() ?: 0

                                                if (pointCloudNodes.isNotEmpty()) {
                                                }
                                                pointCloudNodes.toList().forEach { removePointCloudNode(it) }

                                                val pointsBuffer = pointCloud.points
                                                for (index in 0 until pointsSize) {
                                                    val pointIndex = index * 4
                                                    val position =
                                                        Position(
                                                            pointsBuffer[pointIndex],
                                                            pointsBuffer[pointIndex + 1],
                                                            pointsBuffer[pointIndex + 2],
                                                        )
                                                    val confidence = pointsBuffer[pointIndex + 3]
                                                    addPointCloudNode(index, position, confidence)
                                                }

                                                pointCloud.release()
                                            }
                                        }
                                    }
                                }

                                frame.getUpdatedTrackables(Plane::class.java).forEach { plane ->
                                    if (plane.trackingState == TrackingState.TRACKING &&
                                        !detectedPlanes.contains(plane)
                                    ) {
                                        detectedPlanes.add(plane)
                                        mainScope.launch {
                                            sessionChannel.invokeMethod("onPlaneDetected", detectedPlanes.size)
                                        }
                                    }
                                }
                            }
                        }
                    } catch (e: Exception) {
                        when (e) {
                            is SessionPausedException -> {
                                // Ignorer silencieusement cette exception quand la session est en pause
                                Log.d(TAG, "Session paused, skipping frame update")
                            }
                            else -> {
                                Log.e(TAG, "Error during frame update", e)
                                e.printStackTrace()
                            }
                        }
                    }
                }

                setOnGestureListener(
                    onSingleTapConfirmed = { motionEvent: MotionEvent, node: Node? ->
                        if (node != null) {
                            var anchorName: String? = null
                            var currentNode: Node? = node
                            while (currentNode != null) {
                                anchorNodesMap.forEach { (name, anchorNode) ->
                                    if (currentNode == anchorNode) {
                                        anchorName = name
                                        return@forEach
                                    }
                                }
                                if (anchorName != null) break
                                currentNode = currentNode.parent
                            }
                            if(handleTaps) {
                                objectChannel.invokeMethod("onNodeTap", listOf(anchorName))
                            }
                            true
                        } else {
                            session?.update()?.let { frame ->
                                val hitResults = frame.hitTest(motionEvent)

                                Log.d("ArView", "Hit Results count: ${hitResults.size}")

                                val planeHits =
                                    hitResults
                                        .filter { hit ->
                                            val trackable = hit.trackable
                                            trackable is Plane && trackable.trackingState == TrackingState.TRACKING
                                        }.map { hit ->
                                            mapOf(
                                                "type" to 1,
                                                "distance" to hit.distance.toDouble(),
                                                "position" to
                                                    mapOf(
                                                        "x" to hit.hitPose.tx().toDouble(),
                                                        "y" to hit.hitPose.ty().toDouble(),
                                                        "z" to hit.hitPose.tz().toDouble(),
                                                    ),
                                            )
                                        }
                                notifyPlaneOrPointTap(planeHits)
                            }
                            true
                        }
                    },
                )

                if (argShowAnimatedGuide == true && showAnimatedGuide == true) {
                    val handMotionLayout =
                        LayoutInflater
                            .from(context)
                            .inflate(R.layout.sceneform_hand_layout, rootLayout, false)
                            .apply {
                                tag = "hand_motion_layout"
                            }
                    rootLayout.addView(handMotionLayout)
                }

                if (customPlaneTexturePath != null) {
                    try {
                        val loader = FlutterInjector.instance().flutterLoader()
                        val assetKey = loader.getLookupKeyForAsset(customPlaneTexturePath)
                        val customPlaneTexture =
                            ImageTexture
                                .Builder()
                                .bitmap(materialLoader.assets, assetKey)
                                .build(engine)
                        planeRenderer.planeMaterial.defaultInstance.apply {
                            setTexture(PlaneRenderer.MATERIAL_TEXTURE, customPlaneTexture)
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ Erreur lors de l'application de la texture personnalisée: ${e.message}")
                        Log.e(TAG, "Stack trace:", e)
                    }
                } else {
                    Log.i(TAG, "ℹ️ Utilisation de la texture par défaut")
                }
            }
            result.success(null)
        } catch (e: Exception) {
            result.error("AR_VIEW_ERROR", e.message, null)
        }
    }

    private fun handleAddNode(
        nodeData: Map<String, Any>,
        result: MethodChannel.Result,
    ) {
        try {
            mainScope.launch {
                val node = buildModelNode(nodeData)
                if (node != null) {
                    sceneView.addChildNode(node)
                    node.name?.let { nodeName ->
                        nodesMap[nodeName] = node
                    }
                    result.success(true)
                } else {
                    result.success(false)
                }
            }
        } catch (e: Exception) {
            result.success(false)
        }
    }

    private fun handleRemoveNode(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        try {
            val nodeData = call.arguments as? Map<String, Any>
            val nodeName = nodeData?.get("name") as? String
            
            if (nodeName == null) {
                result.error("INVALID_ARGUMENT", "Node name is required", null)
                return
            }
            
            Log.d(TAG, "Attempting to remove node with name: $nodeName")
            Log.d(TAG, "Current nodes in map: ${nodesMap.keys}")
            
            nodesMap[nodeName]?.let { node ->
                // Détacher d'abord le nœud de son parent s'il en a un
                node.parent?.removeChildNode(node)
                // Puis le retirer de la scène principale
                sceneView.removeChildNode(node)
                // Nettoyer les ressources du nœud
                node.destroy()
                // Enfin le retirer de notre Map
                nodesMap.remove(nodeName)
                
                Log.d(TAG, "Node removed successfully and destroyed")
                result.success(nodeName)
            } ?: run {
                Log.e(TAG, "Node not found in nodesMap")
                result.error("NODE_NOT_FOUND", "Node with name $nodeName not found", null)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error removing node", e)
            result.error("REMOVE_NODE_ERROR", e.message, null)
        }
    }

    private fun handleTransformNode(
    call: MethodCall,
    result: MethodChannel.Result,
) {
    try {
        if (handlePans || handleRotation) {
            val name = call.argument<String>("name")
            val newTransformation: ArrayList<Double>? = call.argument<ArrayList<Double>>("transformation")

            if (name == null) {
                result.error("INVALID_ARGUMENT", "Node name is required", null)
                return
            }
            nodesMap[name]?.let { node ->
                newTransformation?.let { transform ->
                    if (transform.size != 16) {
                        result.error("INVALID_TRANSFORMATION", "Transformation must be a 4x4 matrix (16 values)", null)
                        return
                    }

                    node.apply {
                        transform(
                            position = ScenePosition(
                                x = transform[12].toFloat(),
                                y = transform[13].toFloat(),
                                z = transform[14].toFloat()
                            ),
                            rotation = SceneRotation(
                                x = kotlin.math.atan2(transform[6].toFloat(), transform[10].toFloat()),
                                y = kotlin.math.atan2(-transform[2].toFloat(), 
                                    kotlin.math.sqrt(transform[6].toFloat() * transform[6].toFloat() + 
                                    transform[10].toFloat() * transform[10].toFloat())),
                                z = kotlin.math.atan2(transform[1].toFloat(), transform[0].toFloat())
                            ),
                            scale = SceneScale(
                                x = kotlin.math.sqrt((transform[0] * transform[0] + transform[1] * transform[1] + transform[2] * transform[2]).toFloat()),
                                y = kotlin.math.sqrt((transform[4] * transform[4] + transform[5] * transform[5] + transform[6] * transform[6]).toFloat()),
                                z = kotlin.math.sqrt((transform[8] * transform[8] + transform[9] * transform[9] + transform[10] * transform[10]).toFloat())
                            )
                        )
                    }
                    result.success(null)
                } ?: result.error("INVALID_TRANSFORMATION", "Transformation is required", null)
            } ?: result.error("NODE_NOT_FOUND", "Node with name $name not found", null)
        }
    } catch (e: Exception) {
        result.error("TRANSFORM_NODE_ERROR", e.message, null)
    }
}

    private fun handleHostCloudAnchor(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        try {
            val anchorId = call.argument<String>("anchorId")
            if (anchorId == null) {
                result.error("INVALID_ARGUMENT", "Anchor ID is required", null)
                return
            }

            val session = sceneView.session
            if (session == null) {
                result.error("SESSION_ERROR", "AR Session is not available", null)
                return
            }

            if (!session.canHostCloudAnchor(sceneView.cameraNode)) {
                result.error("HOSTING_ERROR", "Insufficient visual data to host", null)
                return
            }

            val anchor = session.allAnchors.find { it.cloudAnchorId == anchorId }
            if (anchor == null) {
                result.error("ANCHOR_NOT_FOUND", "Anchor with ID $anchorId not found", null)
                return
            }

            val cloudAnchorNode = CloudAnchorNode(sceneView.engine, anchor)
            cloudAnchorNode.host(session) { cloudAnchorId, state ->
                if (state == CloudAnchorState.SUCCESS && cloudAnchorId != null) {
                    result.success(cloudAnchorId)
                } else {
                    result.error("HOSTING_ERROR", "Failed to host cloud anchor: $state", null)
                }
            }
            sceneView.addChildNode(cloudAnchorNode)
        } catch (e: Exception) {
            result.error("HOST_CLOUD_ANCHOR_ERROR", e.message, null)
        }
    }

    private fun handleResolveCloudAnchor(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        try {
            val cloudAnchorId = call.argument<String>("cloudAnchorId")
            if (cloudAnchorId == null) {
                result.error("INVALID_ARGUMENT", "Cloud Anchor ID is required", null)
                return
            }

            val session = sceneView.session
            if (session == null) {
                result.error("SESSION_ERROR", "AR Session is not available", null)
                return
            }

            CloudAnchorNode.resolve(
                sceneView.engine,
                session,
                cloudAnchorId,
            ) { state, node ->
                if (!state.isError && node != null) {
                    sceneView.addChildNode(node)
                    result.success(null)
                } else {
                    result.error("RESOLVE_ERROR", "Failed to resolve cloud anchor: $state", null)
                }
            }
        } catch (e: Exception) {
            result.error("RESOLVE_CLOUD_ANCHOR_ERROR", e.message, null)
        }
    }

    private fun handleRemoveAnchor(
        anchorName: String?,
        result: MethodChannel.Result,
    ) {
        try {
            if (anchorName == null) {
                result.error("INVALID_ARGUMENT", "Anchor name is required", null)
                return
            }

            val anchor = anchorNodesMap[anchorName]
            if (anchor != null) {
                sceneView.removeChildNode(anchor)
                anchor.anchor?.detach()
                result.success(null)
            } else {
                result.error("ANCHOR_NOT_FOUND", "Anchor with name $anchorName not found", null)
            }
        } catch (e: Exception) {
            result.error("REMOVE_ANCHOR_ERROR", e.message, null)
        }
    }

    private fun findStableMeasurementHit(
        frame: Frame,
        centerX: Float,
        centerY: Float,
    ): com.google.ar.core.HitResult? {
        /*
         * Fast, measurement-safe Point-A acquisition.
         *
         * We still require a genuinely tracked ARCore result, but we search
         * a modest neighbourhood around the reticle instead of waiting for an
         * exact centre pixel to become trackable. This greatly reduces START
         * delay while preserving real-world depth.
         *
         * The search stays close enough to the reticle to avoid jumping to a
         * remote surface. Exact centre is always tried first.
         */
        val offsets = arrayOf(
            0f to 0f,

            -18f to 0f,
            18f to 0f,
            0f to -18f,
            0f to 18f,
            -18f to -18f,
            18f to -18f,
            -18f to 18f,
            18f to 18f,

            -36f to 0f,
            36f to 0f,
            0f to -36f,
            0f to 36f,
            -36f to -36f,
            36f to -36f,
            -36f to 36f,
            36f to 36f,

            -54f to 0f,
            54f to 0f,
            0f to -54f,
            0f to 54f,
        )

        for ((dx, dy) in offsets) {
            val x = centerX + dx
            val y = centerY + dy

            if (
                x < 0f ||
                y < 0f ||
                x >= sceneView.width.toFloat() ||
                y >= sceneView.height.toFloat()
            ) {
                continue
            }

            val normalHit = frame.hitTest(x, y)
                .firstOrNull { hitResult ->
                    val trackable = hitResult.trackable

                    when (trackable) {
                        is Plane ->
                            trackable.trackingState == TrackingState.TRACKING &&
                                trackable.isPoseInPolygon(hitResult.hitPose)

                        is DepthPoint ->
                            trackable.trackingState == TrackingState.TRACKING

                        is Point ->
                            trackable.trackingState == TrackingState.TRACKING

                        else -> false
                    }
                }

            if (normalHit != null) {
                return normalHit
            }

            /*
             * FULL_TRACKING Instant Placement has already refined against
             * visual geometry, so it is safe to use. APPROXIMATE_DISTANCE is
             * deliberately rejected here.
             */
            val stableInstantHit = frame.hitTestInstantPlacement(
                x,
                y,
                1.0f,
            ).firstOrNull { hitResult ->
                val trackable = hitResult.trackable
                trackable is InstantPlacementPoint &&
                    trackable.trackingState == TrackingState.TRACKING &&
                    trackable.trackingMethod ==
                        InstantPlacementPoint.TrackingMethod.FULL_TRACKING
            }

            if (stableInstantHit != null) {
                return stableInstantHit
            }
        }

        return null
    }

    private fun handleGetCenterHitTest(result: MethodChannel.Result) {
        try {
            val frame = latestFrame

            if (
                frame == null ||
                frame.camera.trackingState != TrackingState.TRACKING
            ) {
                result.success(null)
                return
            }

            val centerX = sceneView.width / 2f
            val centerY = sceneView.height / 2f

            if (centerX <= 0f || centerY <= 0f) {
                result.success(null)
                return
            }

            val stableHit = findStableMeasurementHit(
                frame,
                centerX,
                centerY,
            )

            val nowMs = SystemClock.elapsedRealtime()

            if (stableHit != null) {
                cachedStableMeasurementPose = stableHit.hitPose
                cachedStableMeasurementPoseDistance = stableHit.distance
                cachedStableMeasurementPoseTimeMs = nowMs

                result.success(
                    mapOf(
                        "type" to 1,
                        "distance" to stableHit.distance.toDouble(),
                        "instant" to (stableHit.trackable is InstantPlacementPoint),
                        "position" to mapOf(
                            "x" to stableHit.hitPose.tx().toDouble(),
                            "y" to stableHit.hitPose.ty().toDouble(),
                            "z" to stableHit.hitPose.tz().toDouble(),
                        ),
                    )
                )
                return
            }

            /*
             * Fast visual readiness:
             *
             * If we very recently observed a real tracked depth near the
             * reticle, use that measured distance as Instant Placement's
             * estimate for the current centre pixel. This gives immediate
             * reticle feedback without falling back to the arbitrary 1.0 m
             * scale that caused the HEIGHT error.
             */
            val cachedDistance = cachedStableMeasurementPoseDistance
            val cacheAgeMs = nowMs - cachedStableMeasurementPoseTimeMs

            if (
                cachedDistance != null &&
                cachedDistance > 0.05f &&
                cacheAgeMs in 0..8000
            ) {
                val instantHit = frame.hitTestInstantPlacement(
                    centerX,
                    centerY,
                    cachedDistance,
                ).firstOrNull()

                if (instantHit != null) {
                    result.success(
                        mapOf(
                            "type" to 1,
                            "distance" to instantHit.distance.toDouble(),
                            "instant" to true,
                            "position" to mapOf(
                                "x" to instantHit.hitPose.tx().toDouble(),
                                "y" to instantHit.hitPose.ty().toDouble(),
                                "z" to instantHit.hitPose.tz().toDouble(),
                            ),
                        )
                    )
                    return
                }
            }

            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Center hit test failed", e)
            result.error("CENTER_HIT_TEST_ERROR", e.message, null)
        }
    }

    private fun handleLockCenterMeasurementAnchor(result: MethodChannel.Result) {
        try {
            val frame = latestFrame

            if (
                frame == null ||
                frame.camera.trackingState != TrackingState.TRACKING
            ) {
                result.success(null)
                return
            }

            val centerX = sceneView.width / 2f
            val centerY = sceneView.height / 2f

            if (centerX <= 0f || centerY <= 0f) {
                result.success(null)
                return
            }

            val nowMs = SystemClock.elapsedRealtime()

            /*
             * First choice:
             * Try to obtain a fresh, real tracked ARCore hit close
             * to the centre reticle.
             */
            val stableHit = findStableMeasurementHit(
                frame,
                centerX,
                centerY,
            )

            val anchor: Anchor? = if (stableHit != null) {
                cachedStableMeasurementPose = stableHit.hitPose
                cachedStableMeasurementPoseDistance = stableHit.distance
                cachedStableMeasurementPoseTimeMs = nowMs

                try {
                    stableHit.createAnchor()
                } catch (e: Exception) {
                    /*
                     * A valid tracked hit exists. If ARCore fails to create
                     * the anchor directly from that HitResult, preserve the
                     * same measured pose by creating a session anchor.
                     */
                    sceneView.session?.createAnchor(
                        stableHit.hitPose
                    )
                }
            } else {
                /*
                 * No fresh hit at the exact START moment.
                 *
                 * The reticle may have had a valid tracked hit only a few
                 * milliseconds earlier, so use the fresh cached ARCore pose
                 * rather than requiring repeated START presses.
                 */
                val cachedPose = cachedStableMeasurementPose
                val cachedDistance = cachedStableMeasurementPoseDistance
                val cacheAgeMs = nowMs - cachedStableMeasurementPoseTimeMs

                if (
                    cachedPose != null &&
                    cachedDistance != null &&
                    cachedDistance > 0.05f &&
                    cacheAgeMs in 0..8000
                ) {
                    /*
                     * First fallback:
                     * Try Instant Placement at the current centre reticle
                     * using the most recently measured real-world distance.
                     */
                    val instantHit =
                        try {
                            frame.hitTestInstantPlacement(
                                centerX,
                                centerY,
                                cachedDistance,
                            ).firstOrNull()
                        } catch (e: Exception) {
                            null
                        }

                    if (instantHit != null) {
                        try {
                            sceneView.session?.createAnchor(
                                instantHit.hitPose
                            )
                        } catch (e: Exception) {
                            /*
                             * If anchor creation from Instant Placement fails,
                             * immediately use the recent verified stable pose.
                             */
                            sceneView.session?.createAnchor(
                                cachedPose
                            )
                        }
                    } else {
                        /*
                         * Important reliability fallback:
                         * Previously START could return null here, forcing
                         * the user to press START repeatedly.
                         */
                        sceneView.session?.createAnchor(
                            cachedPose
                        )
                    }
                } else if (
                    cachedPose != null &&
                    cacheAgeMs in 0..8000
                ) {
                    /*
                     * Safe final fallback:
                     * A recent stable pose exists even if its distance cache
                     * is unavailable.
                     */
                    sceneView.session?.createAnchor(
                        cachedPose
                    )
                } else {
                    null
                }
            }

            if (anchor == null) {
                result.success(null)
                return
            }

            // Point A remains immutable after START.
            measurementAnchor?.detach()
            measurementAnchor = anchor
            measurementStartScreenX = centerX
            measurementStartScreenY = centerY

            val pose = anchor.pose

            result.success(
                mapOf(
                    "x" to pose.tx().toDouble(),
                    "y" to pose.ty().toDouble(),
                    "z" to pose.tz().toDouble(),
                )
            )
        } catch (e: Exception) {
            Log.e(TAG, "Failed to lock measurement anchor", e)
            result.error("MEASUREMENT_ANCHOR_ERROR", e.message, null)
        }
    }

    private fun handleGetMeasurementAnchorPosition(result: MethodChannel.Result) {
        try {
            // Always return the original START anchor. Point A is immutable.
            val anchor = measurementAnchor

            if (anchor == null || anchor.trackingState == TrackingState.STOPPED) {
                result.success(null)
                return
            }

            val pose = anchor.pose

            result.success(
                mapOf(
                    "x" to pose.tx().toDouble(),
                    "y" to pose.ty().toDouble(),
                    "z" to pose.tz().toDouble(),
                )
            )
        } catch (e: Exception) {
            Log.e(TAG, "Failed to read measurement anchor", e)
            result.error("MEASUREMENT_ANCHOR_POSITION_ERROR", e.message, null)
        }
    }

    private fun handleGetMeasurementAnchorScreenPosition(result: MethodChannel.Result) {
        try {
            val frame = latestFrame
            val anchor = measurementAnchor

            if (
                frame == null ||
                anchor == null ||
                frame.camera.trackingState != TrackingState.TRACKING ||
                anchor.trackingState == TrackingState.STOPPED ||
                sceneView.width <= 0 ||
                sceneView.height <= 0
            ) {
                result.success(null)
                return
            }

            val viewMatrix = FloatArray(16)
            val projectionMatrix = FloatArray(16)
            val camera = frame.camera

            camera.getViewMatrix(viewMatrix, 0)
            camera.getProjectionMatrix(projectionMatrix, 0, 0.1f, 100.0f)

            val pose = anchor.pose
            val worldPoint = floatArrayOf(
                pose.tx(),
                pose.ty(),
                pose.tz(),
                1.0f,
            )

            val cameraPoint = FloatArray(4)
            val clipPoint = FloatArray(4)

            GLMatrix.multiplyMV(
                cameraPoint,
                0,
                viewMatrix,
                0,
                worldPoint,
                0,
            )

            GLMatrix.multiplyMV(
                clipPoint,
                0,
                projectionMatrix,
                0,
                cameraPoint,
                0,
            )

            val w = clipPoint[3]

            if (w <= 0.0001f) {
                result.success(null)
                return
            }

            val ndcX = clipPoint[0] / w
            val ndcY = clipPoint[1] / w

            val normalizedX = (ndcX + 1.0f) / 2.0f
            val normalizedY = (1.0f - ndcY) / 2.0f

            result.success(
                mapOf(
                    "x" to normalizedX.toDouble(),
                    "y" to normalizedY.toDouble(),
                    "visible" to (
                        normalizedX >= 0.0f &&
                            normalizedX <= 1.0f &&
                            normalizedY >= 0.0f &&
                            normalizedY <= 1.0f
                    ),
                )
            )
        } catch (e: Exception) {
            Log.e(TAG, "Failed to project measurement anchor", e)
            result.error(
                "MEASUREMENT_ANCHOR_SCREEN_ERROR",
                e.message,
                null,
            )
        }
    }


    private fun handleGetMeasurementVerticalGuideScreenPosition(result: MethodChannel.Result) {
        try {
            val frame = latestFrame
            val anchor = measurementAnchor

            if (
                frame == null ||
                anchor == null ||
                frame.camera.trackingState != TrackingState.TRACKING ||
                anchor.trackingState == TrackingState.STOPPED ||
                sceneView.width <= 0 ||
                sceneView.height <= 0
            ) {
                result.success(null)
                return
            }

            val camera = frame.camera
            val viewMatrix = FloatArray(16)
            val projectionMatrix = FloatArray(16)

            camera.getViewMatrix(viewMatrix, 0)
            camera.getProjectionMatrix(
                projectionMatrix,
                0,
                0.1f,
                100.0f,
            )

            fun projectPoint(
                worldX: Float,
                worldY: Float,
                worldZ: Float,
            ): Map<String, Any>? {
                val worldPoint = floatArrayOf(
                    worldX,
                    worldY,
                    worldZ,
                    1.0f,
                )

                val cameraPoint = FloatArray(4)
                val clipPoint = FloatArray(4)

                GLMatrix.multiplyMV(
                    cameraPoint,
                    0,
                    viewMatrix,
                    0,
                    worldPoint,
                    0,
                )

                GLMatrix.multiplyMV(
                    clipPoint,
                    0,
                    projectionMatrix,
                    0,
                    cameraPoint,
                    0,
                )

                val w = clipPoint[3]

                if (w <= 0.0001f) {
                    return null
                }

                val ndcX = clipPoint[0] / w
                val ndcY = clipPoint[1] / w

                val normalizedX =
                    (ndcX + 1.0f) / 2.0f
                val normalizedY =
                    (1.0f - ndcY) / 2.0f

                return mapOf(
                    "x" to normalizedX.toDouble(),
                    "y" to normalizedY.toDouble(),
                    "visible" to (
                        normalizedX >= -1.0f &&
                            normalizedX <= 2.0f &&
                            normalizedY >= -1.0f &&
                            normalizedY <= 2.0f
                    ),
                )
            }

            val pose = anchor.pose

            // ARCore world Y is gravity aligned. A point directly above
            // the anchor therefore defines a true 90-degree vertical
            // reference in the real world.
            val anchorPoint = projectPoint(
                pose.tx(),
                pose.ty(),
                pose.tz(),
            )

            val upperPoint = projectPoint(
                pose.tx(),
                pose.ty() + 1.0f,
                pose.tz(),
            )

            /*
             * A one-metre horizontal reference through Point A.
             *
             * Use the camera-facing horizontal direction so the reference
             * remains meaningful on screen while ARCore world Y continues
             * to define true vertical. Flutter will use this projected
             * one-metre span to calibrate WIDTH ruler ticks.
             */
            val cameraPose = camera.pose
            val forward = cameraPose.zAxis
            var horizontalX = -forward[2]
            var horizontalZ = forward[0]

            val horizontalLength =
                kotlin.math.sqrt(
                    (horizontalX * horizontalX) +
                        (horizontalZ * horizontalZ)
                )

            if (horizontalLength > 0.0001f) {
                horizontalX /= horizontalLength
                horizontalZ /= horizontalLength
            } else {
                horizontalX = 1.0f
                horizontalZ = 0.0f
            }

            val rightPoint = projectPoint(
                pose.tx() + horizontalX,
                pose.ty(),
                pose.tz() + horizontalZ,
            )

            if (
                anchorPoint == null ||
                upperPoint == null ||
                rightPoint == null
            ) {
                result.success(null)
                return
            }

            result.success(
                mapOf(
                    "anchor" to anchorPoint,
                    "upper" to upperPoint,
                    "right" to rightPoint,
                    "referenceMeters" to 1.0,
                )
            )
        } catch (e: Exception) {
            Log.e(
                TAG,
                "Failed to project vertical measurement guide",
                e,
            )
            result.error(
                "MEASUREMENT_VERTICAL_GUIDE_ERROR",
                e.message,
                null,
            )
        }
    }

    /*
     * Native HEIGHT ruler geometry.
     *
     * Point A is the immutable ARCore anchor created at START.
     *
     * HEIGHT must NOT use a new ARCore surface hit for Point B because,
     * while the user tilts the phone upward, the centre reticle may begin
     * hitting a different plane / depth point / feature point. That can make
     * the measured Y value suddenly decrease.
     *
     * Instead, cast the camera's centre viewing ray and calculate the point
     * where that ray is horizontally closest to the true world-vertical line
     * passing through Point A. ARCore world Y is gravity aligned, therefore
     * the resulting endpoint changes only in Y while X/Z remain locked to A.
     */
    private fun handleGetNativeHeightRuler(result: MethodChannel.Result) {
        try {
            val frame = latestFrame
            val anchor = measurementAnchor

            if (
                frame == null ||
                anchor == null ||
                frame.camera.trackingState != TrackingState.TRACKING ||
                anchor.trackingState == TrackingState.STOPPED ||
                sceneView.width <= 0 ||
                sceneView.height <= 0
            ) {
                result.success(null)
                return
            }

            val camera = frame.camera
            val startPose = anchor.pose

            val startX = startPose.tx()
            val startY = startPose.ty()
            val startZ = startPose.tz()

            /*
             * HEIGHT geometry:
             *
             * Point A is fixed in world space.
             * Point B must stay on the true gravity-aligned vertical line
             * through Point A, therefore:
             *
             *     Xb = Xa
             *     Zb = Za
             *
             * We do NOT estimate Point B from a new ARCore hit, and we do
             * NOT use a "closest point" on the camera ray. A camera ray and
             * Point A's vertical line generally do not intersect exactly;
             * using closest approach can substantially under-estimate height.
             *
             * Instead we solve the camera projection directly.
             *
             * The centre reticle has OpenGL NDC Y = 0.  For a world point
             * (Xa, Y, Za), clip-space Y is linear in Y.  We solve for the
             * world Y that makes clip-space Y exactly zero. This gives the
             * point on Point A's true vertical line that lies at the same
             * screen height as the centre reticle.
             */

            val viewMatrix = FloatArray(16)
            val projectionMatrix = FloatArray(16)
            val viewProjectionMatrix = FloatArray(16)

            camera.getViewMatrix(viewMatrix, 0)
            camera.getProjectionMatrix(
                projectionMatrix,
                0,
                0.1f,
                100.0f,
            )

            GLMatrix.multiplyMM(
                viewProjectionMatrix,
                0,
                projectionMatrix,
                0,
                viewMatrix,
                0,
            )

            /*
             * Android/OpenGL matrices are column-major.
             *
             * clipY =
             *     M[1]  * X +
             *     M[5]  * Y +
             *     M[9]  * Z +
             *     M[13]
             *
             * At the centre reticle NDC Y = 0, therefore clipY = 0.
             */
            val yCoefficient = viewProjectionMatrix[5]

            if (kotlin.math.abs(yCoefficient) <= 0.000001f) {
                result.success(null)
                return
            }

            val fixedPart =
                (viewProjectionMatrix[1] * startX) +
                    (viewProjectionMatrix[9] * startZ) +
                    viewProjectionMatrix[13]

            val solvedWorldY =
                -fixedPart / yCoefficient

            if (
                solvedWorldY.isNaN() ||
                solvedWorldY.isInfinite()
            ) {
                result.success(null)
                return
            }

            val endX = startX
            val endY = solvedWorldY
            val endZ = startZ

            fun projectWorldPoint(
                worldX: Float,
                worldY: Float,
                worldZ: Float,
            ): Map<String, Any>? {
                val worldPoint = floatArrayOf(
                    worldX,
                    worldY,
                    worldZ,
                    1.0f,
                )

                val clipPoint = FloatArray(4)

                GLMatrix.multiplyMV(
                    clipPoint,
                    0,
                    viewProjectionMatrix,
                    0,
                    worldPoint,
                    0,
                )

                val w = clipPoint[3]

                if (w <= 0.0001f) {
                    return null
                }

                val ndcX = clipPoint[0] / w
                val ndcY = clipPoint[1] / w

                val normalizedX =
                    (ndcX + 1.0f) / 2.0f
                val normalizedY =
                    (1.0f - ndcY) / 2.0f

                return mapOf(
                    "x" to normalizedX.toDouble(),
                    "y" to normalizedY.toDouble(),
                    "visible" to (
                        normalizedX >= -1.0f &&
                            normalizedX <= 2.0f &&
                            normalizedY >= -1.0f &&
                            normalizedY <= 2.0f
                    ),
                )
            }

            val startScreen = projectWorldPoint(
                startX,
                startY,
                startZ,
            )

            val endScreen = projectWorldPoint(
                endX,
                endY,
                endZ,
            )

            if (startScreen == null || endScreen == null) {
                result.success(null)
                return
            }

            result.success(
                mapOf(
                    "startWorld" to mapOf(
                        "x" to startX.toDouble(),
                        "y" to startY.toDouble(),
                        "z" to startZ.toDouble(),
                    ),
                    "endWorld" to mapOf(
                        "x" to endX.toDouble(),
                        "y" to endY.toDouble(),
                        "z" to endZ.toDouble(),
                    ),
                    "startScreen" to startScreen,
                    "endScreen" to endScreen,
                    "meters" to kotlin.math.abs(endY - startY).toDouble(),
                    "stableTarget" to true,
                    "axis" to "worldY_centerProjection",
                )
            )
        } catch (e: Exception) {
            Log.e(TAG, "Failed to calculate native HEIGHT ruler", e)
            result.error(
                "NATIVE_HEIGHT_RULER_ERROR",
                e.message,
                null,
            )
        }
    }

    private fun handleClearMeasurementAnchor(result: MethodChannel.Result) {
        try {
            measurementAnchor?.detach()
            measurementAnchor = null
            measurementStartScreenX = null
            measurementStartScreenY = null

            // Do NOT clear cachedStableMeasurementPose here.
            // Flutter calls clearMeasurementAnchor() immediately before START.
            // Keeping the fresh pre-START stable pose allows Point A to lock
            // immediately. The age check below prevents stale poses being used.
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to clear measurement anchor", e)
            result.error("MEASUREMENT_ANCHOR_CLEAR_ERROR", e.message, null)
        }
    }

    private fun handleGetCameraPose(result: MethodChannel.Result) {
        try {
            val frame = sceneView.session?.update()
            val cameraPose = frame?.camera?.pose
            if (cameraPose != null) {
                val poseData =
                    mapOf(
                        "position" to
                            mapOf(
                                "x" to cameraPose.tx(),
                                "y" to cameraPose.ty(),
                                "z" to cameraPose.tz(),
                            ),
                        "rotation" to
                            mapOf(
                                "x" to cameraPose.rotationQuaternion[0],
                                "y" to cameraPose.rotationQuaternion[1],
                                "z" to cameraPose.rotationQuaternion[2],
                                "w" to cameraPose.rotationQuaternion[3],
                            ),
                    )
                result.success(poseData)
            } else {
                result.error("NO_CAMERA_POSE", "Camera pose is not available", null)
            }
        } catch (e: Exception) {
            result.error("CAMERA_POSE_ERROR", e.message, null)
        }
    }

    private fun handleGetAnchorPose(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        try {
            val anchorId = call.argument<String>("anchorId")
            if (anchorId == null) {
                result.error("INVALID_ARGUMENT", "Anchor ID is required", null)
                return
            }

            val anchor = sceneView.session?.allAnchors?.find { it.cloudAnchorId == anchorId }
            if (anchor != null) {
                val anchorPose = anchor.pose
                val poseData =
                    mapOf(
                        "position" to
                            mapOf(
                                "x" to anchorPose.tx(),
                                "y" to anchorPose.ty(),
                                "z" to anchorPose.tz(),
                            ),
                        "rotation" to
                            mapOf(
                                "x" to anchorPose.rotationQuaternion[0],
                                "y" to anchorPose.rotationQuaternion[1],
                                "z" to anchorPose.rotationQuaternion[2],
                                "w" to anchorPose.rotationQuaternion[3],
                            ),
                    )
                result.success(poseData)
            } else {
                result.error("ANCHOR_NOT_FOUND", "Anchor with ID $anchorId not found", null)
            }
        } catch (e: Exception) {
            result.error("ANCHOR_POSE_ERROR", e.message, null)
        }
    }

    private fun handleSnapshot(result: MethodChannel.Result) {
        try {
            mainScope.launch {
                val bitmap =
                    withContext(Dispatchers.Main) {
                        val bitmap =
                            Bitmap.createBitmap(
                                sceneView.width,
                                sceneView.height,
                                Bitmap.Config.ARGB_8888,
                            )

                        try {
                            val listener =
                                PixelCopy.OnPixelCopyFinishedListener { copyResult ->
                                    if (copyResult == PixelCopy.SUCCESS) {
                                        val byteStream = java.io.ByteArrayOutputStream()
                                        bitmap.compress(Bitmap.CompressFormat.PNG, 100, byteStream)
                                        val byteArray = byteStream.toByteArray()
                                        result.success(byteArray)
                                    } else {
                                        result.error("SNAPSHOT_ERROR", "Failed to capture snapshot", null)
                                    }
                                }

                            PixelCopy.request(
                                sceneView,
                                bitmap,
                                listener,
                                Handler(Looper.getMainLooper()),
                            )
                        } catch (e: Exception) {
                            result.error("SNAPSHOT_ERROR", e.message, null)
                        }
                    }
            }
        } catch (e: Exception) {
            result.error("SNAPSHOT_ERROR", e.message, null)
        }
    }

    private fun handleShowPlanes(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        try {
            val showPlanes = call.argument<Boolean>("showPlanes") ?: false
            sceneView.apply {
                planeRenderer.isEnabled = showPlanes
            }
            result.success(null)
        } catch (e: Exception) {
            result.error("SHOW_PLANES_ERROR", e.message, null)
        }
    }

    private fun handleAddAnchor(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        try {
            val anchorType = call.argument<Int>("type")
            if (anchorType == 0) { // Plane Anchor
                val transform = call.argument<ArrayList<Double>>("transformation")
                val name = call.argument<String>("name")

                if (name != null && transform != null) {
                    try {
                        // Décomposer la matrice de transformation
                        val (position, rotation) = deserializeMatrix4(transform)

                        val pose =
                            Pose(
                                floatArrayOf(position.x, position.y, position.z),
                                floatArrayOf(rotation.x, rotation.y, rotation.z, 1f),
                            )

                        val anchor = sceneView.session?.createAnchor(pose)
                        if (anchor != null) {
                            val anchorNode = AnchorNode(sceneView.engine, anchor)
                            try {
                                anchorNode.transform =
                                    Transform(
                                        position = position,
                                        rotation = rotation,
                                    )
                            } catch (e: Exception) {
                                Log.w(TAG, "Transform warning suppressed: ${e.message}")
                            }

                            sceneView.addChildNode(anchorNode)
                            anchorNodesMap[name] = anchorNode
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Error in transform calculation: ${e.message}")
                        result.success(false)
                    }
                } else {
                    result.success(false)
                }
            } else {
                result.success(false)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in handleAddAnchor: ${e.message}")
            e.printStackTrace()
            result.success(false)
        }
    }

    private fun handleInitGoogleCloudAnchorMode(result: MethodChannel.Result) {
        try {
            Log.d(TAG, "🔄 Initialisation du mode Cloud Anchor...")
            sceneView.session?.let { session ->
                session.configure(session.config.apply {
                    cloudAnchorMode = Config.CloudAnchorMode.ENABLED
                })
            }
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "❌ Erreur lors de l'initialisation du mode Cloud Anchor", e)
            mainScope.launch {
                sessionChannel.invokeMethod("onError", listOf("Error initializing cloud anchor mode: ${e.message}"))
            }
            result.error("CLOUD_ANCHOR_INIT_ERROR", e.message, null)
        }
    }

    private fun handleUploadAnchor(call: MethodCall, result: MethodChannel.Result) {
        try {
            val anchorName = call.argument<String>("name")
            Log.d(TAG, "⚓ Début de l'upload de l'ancre: $anchorName")
            
            // Vérifier si le mode Cloud Anchor est initialisé
            val session = sceneView.session
            if (session == null) {
                Log.e(TAG, "❌ Erreur: session AR non disponible")
                result.error("SESSION_ERROR", "AR Session is not available", null)
                return
            }

            // Vérifier et initialiser le mode Cloud Anchor si nécessaire
            Log.d(TAG, "🔄 Vérification de la configuration Cloud Anchor...")
            try {
                sceneView.configureSession { session, config ->
                    config.cloudAnchorMode = Config.CloudAnchorMode.ENABLED
                    config.updateMode = Config.UpdateMode.LATEST_CAMERA_IMAGE
                }
                Log.d(TAG, "✅ Mode Cloud Anchor configuré avec succès")
            } catch (e: Exception) {
                Log.e(TAG, "❌ Erreur lors de la configuration du mode Cloud Anchor", e)
                result.error("CLOUD_ANCHOR_CONFIG_ERROR", e.message, null)
                return
            }

            // Continuer avec le reste du code existant...
            if (anchorName == null) {
                Log.e(TAG, "❌ Erreur: nom de l'ancre manquant")
                result.error("INVALID_ARGUMENT", "Anchor name is required", null)
                return
            }

            Log.d(TAG, "📱 Vérification de la capacité à héberger l'ancre cloud...")
            if (!session.canHostCloudAnchor(sceneView.cameraNode)) {
                Log.e(TAG, "❌ Erreur: données visuelles insuffisantes pour héberger l'ancre cloud")
                result.error("HOSTING_ERROR", "Insufficient visual data to host", null)
                return
            }

            val anchorNode = anchorNodesMap[anchorName]
            if (anchorNode == null) {
                Log.e(TAG, "❌ Erreur: ancre non trouvée: $anchorName")
                Log.d(TAG, "📍 Ancres disponibles: ${anchorNodesMap.keys}")
                result.error("ANCHOR_NOT_FOUND", "Anchor not found: $anchorName", null)
                return
            }

            Log.d(TAG, "🔄 Création du CloudAnchorNode...")
            val cloudAnchorNode = CloudAnchorNode(sceneView.engine, anchorNode.anchor!!)
            
            Log.d(TAG, "☁️ Début de l'hébergement de l'ancre cloud...")
            cloudAnchorNode.host(session) { cloudAnchorId, state ->
                Log.d(TAG, "📡 État de l'hébergement: $state, ID: $cloudAnchorId")
                mainScope.launch {
                    if (state == CloudAnchorState.SUCCESS && cloudAnchorId != null) {
                        Log.d(TAG, "✅ Ancre cloud hébergée avec succès: $cloudAnchorId")
                        val args = mapOf(
                            "name" to anchorName,
                            "cloudanchorid" to cloudAnchorId
                        )
                        anchorChannel.invokeMethod("onCloudAnchorUploaded", args)
                        result.success(true)
                    } else {
                        Log.e(TAG, "❌ Échec de l'hébergement de l'ancre cloud: $state")
                        sessionChannel.invokeMethod("onError", listOf("Failed to host cloud anchor: $state"))
                        result.error("HOSTING_ERROR", "Failed to host cloud anchor: $state", null)
                    }
                }
            }
            
            Log.d(TAG, "➕ Ajout du CloudAnchorNode à la scène...")
            sceneView.addChildNode(cloudAnchorNode)
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception lors de l'upload de l'ancre", e)
            Log.e(TAG, "Stack trace:", e)
            result.error("UPLOAD_ANCHOR_ERROR", e.message, null)
        }
    }

    private fun handleDownloadAnchor(call: MethodCall, result: MethodChannel.Result) {
        try {
            val cloudAnchorId = call.argument<String>("cloudanchorid")
            if (cloudAnchorId == null) {
                mainScope.launch {
                    sessionChannel.invokeMethod("onError", listOf("Cloud Anchor ID is required"))
                }
                result.error("INVALID_ARGUMENT", "Cloud Anchor ID is required", null)
                return
            }

            val session = sceneView.session
            if (session == null) {
                mainScope.launch {
                    sessionChannel.invokeMethod("onError", listOf("AR Session is not available"))
                }
                result.error("SESSION_ERROR", "AR Session is not available", null)
                return
            }

            CloudAnchorNode.resolve(
                sceneView.engine,
                session,
                cloudAnchorId
            ) { state, node ->
                mainScope.launch {
                    if (!state.isError && node != null) {
                        sceneView.addChildNode(node)
                        val anchorData = mapOf(
                            "type" to 0,
                            "cloudanchorid" to cloudAnchorId
                        )
                        anchorChannel.invokeMethod(
                            "onAnchorDownloadSuccess",
                            anchorData,
                            object : MethodChannel.Result {
                                override fun success(result: Any?) {
                                    val anchorName = result.toString()
                                    anchorNodesMap[anchorName] = node
                                }

                                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                                    sessionChannel.invokeMethod("onError", listOf("Error registering downloaded anchor: $errorMessage"))
                                }

                                override fun notImplemented() {
                                    sessionChannel.invokeMethod("onError", listOf("Error registering downloaded anchor: not implemented"))
                                }
                            }
                        )
                        result.success(true)
                    } else {
                        sessionChannel.invokeMethod("onError", listOf("Failed to resolve cloud anchor: $state"))
                        result.error("RESOLVE_ERROR", "Failed to resolve cloud anchor: $state", null)
                    }
                }
            }
        } catch (e: Exception) {
            mainScope.launch {
                sessionChannel.invokeMethod("onError", listOf("Error downloading anchor: ${e.message}"))
            }
            result.error("DOWNLOAD_ANCHOR_ERROR", e.message, null)
        }
    }

    override fun getView(): View = rootLayout

    override fun dispose() {
        Log.i(TAG, "dispose")
        sessionChannel.setMethodCallHandler(null)
        objectChannel.setMethodCallHandler(null)
        anchorChannel.setMethodCallHandler(null)
        nodesMap.clear()
        sceneView.destroy()
        pointCloudNodes.toList().forEach { removePointCloudNode(it) }
        pointCloudModelInstances.clear()
    }

    private fun notifyError(error: String) {
        mainScope.launch {
            sessionChannel.invokeMethod("onError", listOf(error))
        }
    }

    private fun notifyCloudAnchorUploaded(args: Map<String, Any>) {
        mainScope.launch {
            anchorChannel.invokeMethod("onCloudAnchorUploaded", args)
        }
    }

    private fun notifyAnchorDownloadSuccess(
        anchorData: Map<String, Any>,
        result: MethodChannel.Result,
    ) {
        mainScope.launch {
            anchorChannel.invokeMethod(
                "onAnchorDownloadSuccess",
                anchorData,
                object : MethodChannel.Result {
                    override fun success(result: Any?) {
                        val anchorName = result.toString()
                        // Mettre à jour l'ancre avec le nom reçu
                    }

                    override fun error(
                        errorCode: String,
                        errorMessage: String?,
                        errorDetails: Any?,
                    ) {
                        notifyError("Error while registering downloaded anchor: $errorMessage")
                    }

                    override fun notImplemented() {
                        notifyError("Error while registering downloaded anchor")
                    }
                },
            )
        }
    }

    private fun notifyPlaneOrPointTap(hitResults: List<Map<String, Any>>) {
        mainScope.launch {
            try {
                val serializedResults = ArrayList<HashMap<String, Any>>()
                hitResults.forEach { hit ->
                    serializedResults.add(serializeHitResult(hit))
                }
                sessionChannel.invokeMethod("onPlaneOrPointTap", serializedResults)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun getPointCloudModelInstance(): ModelInstance? {
        if (pointCloudModelInstances.isEmpty()) {
            pointCloudModelInstances =
                sceneView.modelLoader
                    .createInstancedModel(
                        assetFileLocation = "models/point_cloud.glb",
                        count = 1000,
                    ).toMutableList()
        }
        return pointCloudModelInstances.removeLastOrNull()
    }

    private fun addPointCloudNode(
        id: Int,
        position: Position,
        confidence: Float,
    ) {
        if (pointCloudNodes.size < 1000) { // Limite max de points
            getPointCloudModelInstance()?.let { modelInstance ->
                val pointCloudNode =
                    PointCloudNode(
                        modelInstance = modelInstance,
                        id = id,
                        confidence = confidence,
                    ).apply {
                        this.position = position
                    }
                pointCloudNodes += pointCloudNode
                sceneView.addChildNode(pointCloudNode)
            }
        }
    }

    private fun removePointCloudNode(pointCloudNode: PointCloudNode) {
        pointCloudNodes -= pointCloudNode
        sceneView.removeChildNode(pointCloudNode)
        pointCloudNode.destroy()
    }

    private fun makeWorldOriginNode(context: Context): Node {
        val axisSize = 0.1f
        val axisRadius = 0.005f
        
        // Utilisation de l'engine de sceneView
        val engine = sceneView.engine
        val materialLoader = MaterialLoader(engine, context)
        
        // Création du noeud racine
        val rootNode = Node(engine = engine)
        
        // Création des cylindres avec leurs matériaux respectifs
        val xNode = CylinderNode(
            engine = engine,
            radius = axisRadius,
            height = axisSize,
            materialInstance = materialLoader.createColorInstance(
                color = colorOf(1f, 0f, 0f, 1f),
                metallic = 0.0f,
                roughness = 0.4f
            )
        )
        
        val yNode = CylinderNode(
            engine = engine,
            radius = axisRadius,
            height = axisSize,
            materialInstance = materialLoader.createColorInstance(
                color = colorOf(0f, 1f, 0f, 1f),
                metallic = 0.0f,
                roughness = 0.4f
            )
        )
        
        val zNode = CylinderNode(
            engine = engine,
            radius = axisRadius,
            height = axisSize,
            materialInstance = materialLoader.createColorInstance(
                color = colorOf(0f, 0f, 1f, 1f),
                metallic = 0.0f,
                roughness = 0.4f
            )
        )

        rootNode.addChildNode(xNode)
        rootNode.addChildNode(yNode)
        rootNode.addChildNode(zNode)

        // Positionnement des axes
        xNode.position = Position(axisSize / 2, 0f, 0f)
        xNode.rotation = Rotation(0f, 0f, 90f)  // Rotation autour de l'axe Z

        yNode.position = Position(0f, axisSize / 2, 0f)
        // Pas besoin de rotation pour l'axe Y car il est déjà orienté correctement

        zNode.position = Position(0f, 0f, axisSize / 2)
        zNode.rotation = Rotation(90f, 0f, 0f)  // Rotation autour de l'axe X

        return rootNode
    }

    private fun handleShowWorldOrigin(show: Boolean) {
        if (show) {
            // Création du nouveau node seulement si nécessaire
            if (worldOriginNode == null) {
                worldOriginNode = makeWorldOriginNode(viewContext)
            }
            // Utilisation du safe call operator
            worldOriginNode?.let { node ->
                sceneView.addChildNode(node)
            }
        } else {
            // Utilisation du safe call operator
            worldOriginNode?.let { node ->
                sceneView.removeChildNode(node)
            }
            // Optionnel : remettre à null après suppression
            worldOriginNode = null
        }
    }

    
}
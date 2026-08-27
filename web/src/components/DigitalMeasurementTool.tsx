"use client";

import {
  ChangeEvent,
  MouseEvent,
  useEffect,
  useRef,
  useState,
} from "react";

/* =========================================================
   TYPES
========================================================= */

type Point = {
  x: number;
  y: number;
};

type MeasurementType = "HEIGHT" | "WIDTH" | "LENGTH";

type ReferenceUnit = "FT" | "INCH" | "CM";

type SelectionMode = "REFERENCE" | "MEASURE";

type DirectionMode =
  | "FREE"
  | "HORIZONTAL"
  | "VERTICAL";

type DigitalMeasurementToolProps = {
  measurementType: MeasurementType;
  onUseMeasurement: (value: number) => void;
  onClose: () => void;
};

type CameraDevice = {
  deviceId: string;
  label: string;
};

/* =========================================================
   COMPONENT
========================================================= */

export default function DigitalMeasurementTool({
  measurementType,
  onUseMeasurement,
  onClose,
}: DigitalMeasurementToolProps) {
  /* -------------------------------------------------------
     REFERENCES
  ------------------------------------------------------- */

  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const imageRef = useRef<HTMLImageElement | null>(null);
  const videoRef = useRef<HTMLVideoElement | null>(null);
  const streamRef = useRef<MediaStream | null>(null);

  /* -------------------------------------------------------
     CAMERA / IMAGE STATE
  ------------------------------------------------------- */

  const [imageLoaded, setImageLoaded] = useState(false);
  const [cameraOpen, setCameraOpen] = useState(false);
  const [cameraLoading, setCameraLoading] = useState(false);

  const [cameraDevices, setCameraDevices] =
    useState<CameraDevice[]>([]);

  const [selectedCameraId, setSelectedCameraId] =
    useState("");

  /* -------------------------------------------------------
     MEASUREMENT STATE
  ------------------------------------------------------- */

  const [mode, setMode] =
    useState<SelectionMode>("REFERENCE");

  const [directionMode, setDirectionMode] =
    useState<DirectionMode>("FREE");

  const [referencePoints, setReferencePoints] =
    useState<Point[]>([]);

  const [measurementPoints, setMeasurementPoints] =
    useState<Point[]>([]);

  const [referenceLength, setReferenceLength] =
    useState("");

  const [referenceUnit, setReferenceUnit] =
    useState<ReferenceUnit>("FT");

  const [calculatedFeet, setCalculatedFeet] =
    useState<number | null>(null);

  const [message, setMessage] = useState(
    "Open the camera or upload a photograph to begin."
  );

  /* =========================================================
     HELPERS
  ========================================================= */

  const measurementLabel =
    measurementType === "HEIGHT"
      ? "Height"
      : measurementType === "WIDTH"
        ? "Width"
        : "Length";

  const distance = (
    pointA: Point,
    pointB: Point
  ) => {
    return Math.sqrt(
      Math.pow(pointB.x - pointA.x, 2) +
        Math.pow(pointB.y - pointA.y, 2)
    );
  };

  const convertReferenceToFeet =
    (): number | null => {
      const value = Number(referenceLength);

      if (
        !Number.isFinite(value) ||
        value <= 0
      ) {
        return null;
      }

      if (referenceUnit === "FT") {
        return value;
      }

      if (referenceUnit === "INCH") {
        return value / 12;
      }

      if (referenceUnit === "CM") {
        return value / 30.48;
      }

      return null;
    };

  const applyDirectionConstraint = (
    start: Point,
    end: Point
  ): Point => {
    if (directionMode === "HORIZONTAL") {
      return {
        x: end.x,
        y: start.y,
      };
    }

    if (directionMode === "VERTICAL") {
      return {
        x: start.x,
        y: end.y,
      };
    }

    return end;
  };

  /* =========================================================
     CAMERA FUNCTIONS
  ========================================================= */

  const stopCamera = () => {
    const stream = streamRef.current;

    if (stream) {
      stream.getTracks().forEach((track) => {
        track.stop();
      });
    }

    streamRef.current = null;

    if (videoRef.current) {
      videoRef.current.srcObject = null;
    }

    setCameraOpen(false);
    setCameraLoading(false);
  };

  const loadCameraDevices = async () => {
    if (
      !navigator.mediaDevices ||
      !navigator.mediaDevices.enumerateDevices
    ) {
      return;
    }

    try {
      const devices =
        await navigator.mediaDevices.enumerateDevices();

      const videoDevices = devices
        .filter(
          (device) =>
            device.kind === "videoinput"
        )
        .map((device, index) => ({
          deviceId: device.deviceId,
          label:
            device.label ||
            `Camera ${index + 1}`,
        }));

      setCameraDevices(videoDevices);

      if (
        !selectedCameraId &&
        videoDevices.length > 0
      ) {
        setSelectedCameraId(
          videoDevices[0].deviceId
        );
      }
    } catch (error) {
      console.error(
        "Unable to enumerate cameras:",
        error
      );
    }
  };

  const openCamera = async (
    deviceId?: string
  ) => {
    setMessage("");

    if (
      !navigator.mediaDevices ||
      !navigator.mediaDevices.getUserMedia
    ) {
      setMessage(
        "Live camera access is not supported by this browser."
      );
      return;
    }

    try {
      setCameraLoading(true);

      const oldStream =
        streamRef.current;

      if (oldStream) {
        oldStream
          .getTracks()
          .forEach((track) => {
            track.stop();
          });

        streamRef.current = null;
      }

      let videoConstraints: MediaTrackConstraints;

      if (deviceId) {
        videoConstraints = {
          deviceId: {
            exact: deviceId,
          },
          width: {
            ideal: 1920,
          },
          height: {
            ideal: 1080,
          },
        };
      } else {
        videoConstraints = {
          facingMode: {
            ideal: "environment",
          },
          width: {
            ideal: 1920,
          },
          height: {
            ideal: 1080,
          },
        };
      }

      const stream =
        await navigator.mediaDevices.getUserMedia({
          video: videoConstraints,
          audio: false,
        });

      streamRef.current = stream;

      /*
        IMPORTANT:
        Render the <video> first.
        The useEffect below attaches the stream.
      */
      setCameraOpen(true);
      setCameraLoading(false);

      setMessage(
        "Camera opened. Use the centre pointer to align the object, then capture the frame."
      );

      await loadCameraDevices();

      const videoTrack =
        stream.getVideoTracks()[0];

      if (videoTrack) {
        const settings =
          videoTrack.getSettings();

        if (settings.deviceId) {
          setSelectedCameraId(
            settings.deviceId
          );
        }
      }
    } catch (error) {
      console.error(
        "Camera error:",
        error
      );

      setCameraLoading(false);
      setCameraOpen(false);

      setMessage(
        "Unable to open the camera. Allow camera permission, try another camera, or upload a photograph."
      );
    }
  };

  useEffect(() => {
    if (!cameraOpen) {
      return;
    }

    const video =
      videoRef.current;

    const stream =
      streamRef.current;

    if (!video || !stream) {
      return;
    }

    video.srcObject = stream;

    const startVideo = async () => {
      try {
        await video.play();

        setMessage(
          "Live camera ready. Align the object with the centre pointer and click Capture Frame."
        );
      } catch (error) {
        console.error(
          "Video playback error:",
          error
        );

        setMessage(
          "Camera opened, but preview could not start. Click inside the page and try again."
        );
      }
    };

    startVideo();
  }, [cameraOpen]);

  const switchCamera = async (
    deviceId: string
  ) => {
    setSelectedCameraId(deviceId);

    if (!deviceId) {
      return;
    }

    await openCamera(deviceId);
  };

  /* =========================================================
     CAPTURE / UPLOAD
  ========================================================= */

  const captureCameraFrame = () => {
    const video =
      videoRef.current;

    const canvas =
      canvasRef.current;

    if (!video || !canvas) {
      setMessage(
        "Camera is not ready."
      );
      return;
    }

    if (
      video.readyState < 2 ||
      video.videoWidth === 0 ||
      video.videoHeight === 0
    ) {
      setMessage(
        "Live camera image is not ready yet. Wait 1–2 seconds and try again."
      );
      return;
    }

    const videoWidth =
      video.videoWidth;

    const videoHeight =
      video.videoHeight;

    const maxWidth = 1200;

    const canvasWidth =
      Math.min(
        videoWidth,
        maxWidth
      );

    const scale =
      canvasWidth /
      videoWidth;

    const canvasHeight =
      Math.round(
        videoHeight * scale
      );

    canvas.width =
      canvasWidth;

    canvas.height =
      canvasHeight;

    const ctx =
      canvas.getContext("2d");

    if (!ctx) {
      setMessage(
        "Unable to prepare captured image."
      );
      return;
    }

    ctx.clearRect(
      0,
      0,
      canvas.width,
      canvas.height
    );

    ctx.drawImage(
      video,
      0,
      0,
      canvas.width,
      canvas.height
    );

    const capturedData =
      canvas.toDataURL(
        "image/jpeg",
        0.95
      );

    const image =
      new Image();

    image.onload = () => {
      imageRef.current =
        image;

      setImageLoaded(true);
      setReferencePoints([]);
      setMeasurementPoints([]);
      setCalculatedFeet(null);
      setMode("REFERENCE");

      stopCamera();

      setMessage(
        "Frame captured. Enter the known reference length and select two reference points."
      );

      setTimeout(() => {
        redrawCanvas();
      }, 100);
    };

    image.onerror = () => {
      setMessage(
        "Captured frame could not be processed."
      );
    };

    image.src =
      capturedData;
  };

  const handleImageUpload = (
    event: ChangeEvent<HTMLInputElement>
  ) => {
    const file =
      event.target.files?.[0];

    if (!file) {
      return;
    }

    if (
      !file.type.startsWith("image/")
    ) {
      setMessage(
        "Please select a valid image file."
      );
      return;
    }

    stopCamera();

    const reader =
      new FileReader();

    reader.onload = () => {
      if (
        typeof reader.result !== "string"
      ) {
        return;
      }

      const image =
        new Image();

      image.onload = () => {
        imageRef.current =
          image;

        const canvas =
          canvasRef.current;

        if (!canvas) {
          return;
        }

        const originalWidth =
          image.naturalWidth ||
          image.width;

        const originalHeight =
          image.naturalHeight ||
          image.height;

        const maxWidth = 1200;

        const displayWidth =
          Math.min(
            originalWidth,
            maxWidth
          );

        const ratio =
          originalHeight /
          originalWidth;

        canvas.width =
          displayWidth;

        canvas.height =
          Math.round(
            displayWidth * ratio
          );

        setImageLoaded(true);
        setReferencePoints([]);
        setMeasurementPoints([]);
        setCalculatedFeet(null);
        setMode("REFERENCE");

        setMessage(
          "Photograph loaded. Enter the known reference length and select the two reference points."
        );

        setTimeout(() => {
          redrawCanvas();
        }, 50);
      };

      image.onerror = () => {
        setMessage(
          "The selected photograph could not be loaded."
        );
      };

      image.src =
        reader.result;
    };

    reader.onerror = () => {
      setMessage(
        "The selected photograph could not be read."
      );
    };

    reader.readAsDataURL(file);
  };

  /* =========================================================
     DRAWING
  ========================================================= */

  const drawPoint = (
    ctx: CanvasRenderingContext2D,
    point: Point,
    color: string
  ) => {
    ctx.fillStyle = color;

    ctx.beginPath();

    ctx.arc(
      point.x,
      point.y,
      8,
      0,
      Math.PI * 2
    );

    ctx.fill();

    /*
      Pointer / target ring
    */
    ctx.strokeStyle = "#ffffff";
    ctx.lineWidth = 2;

    ctx.beginPath();

    ctx.arc(
      point.x,
      point.y,
      13,
      0,
      Math.PI * 2
    );

    ctx.stroke();
  };

  const drawLine = (
    ctx: CanvasRenderingContext2D,
    pointA: Point,
    pointB: Point,
    color: string
  ) => {
    ctx.strokeStyle = color;
    ctx.lineWidth = 4;

    ctx.beginPath();

    ctx.moveTo(
      pointA.x,
      pointA.y
    );

    ctx.lineTo(
      pointB.x,
      pointB.y
    );

    ctx.stroke();

    /*
      Small crosshair at both ends
    */

    [pointA, pointB].forEach(
      (point) => {
        ctx.strokeStyle =
          "#ffffff";

        ctx.lineWidth = 2;

        ctx.beginPath();

        ctx.moveTo(
          point.x - 14,
          point.y
        );

        ctx.lineTo(
          point.x + 14,
          point.y
        );

        ctx.moveTo(
          point.x,
          point.y - 14
        );

        ctx.lineTo(
          point.x,
          point.y + 14
        );

        ctx.stroke();
      }
    );
  };

  const redrawCanvas = () => {
    const canvas =
      canvasRef.current;

    const image =
      imageRef.current;

    if (
      !canvas ||
      !image
    ) {
      return;
    }

    const ctx =
      canvas.getContext("2d");

    if (!ctx) {
      return;
    }

    ctx.clearRect(
      0,
      0,
      canvas.width,
      canvas.height
    );

    ctx.drawImage(
      image,
      0,
      0,
      canvas.width,
      canvas.height
    );

    referencePoints.forEach(
      (point) => {
        drawPoint(
          ctx,
          point,
          "#2563eb"
        );
      }
    );

    if (
      referencePoints.length === 2
    ) {
      drawLine(
        ctx,
        referencePoints[0],
        referencePoints[1],
        "#2563eb"
      );
    }

    measurementPoints.forEach(
      (point) => {
        drawPoint(
          ctx,
          point,
          "#16a34a"
        );
      }
    );

    if (
      measurementPoints.length === 2
    ) {
      drawLine(
        ctx,
        measurementPoints[0],
        measurementPoints[1],
        "#16a34a"
      );
    }
  };

  useEffect(() => {
    redrawCanvas();

    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [
    referencePoints,
    measurementPoints,
  ]);

  /* =========================================================
     CALCULATION
  ========================================================= */

  const calculateMeasurement = (
    points: Point[]
  ) => {
    if (
      referencePoints.length !== 2
    ) {
      setMessage(
        "Please select both reference points first."
      );
      return;
    }

    if (points.length !== 2) {
      setMessage(
        "Please select both object measurement points."
      );
      return;
    }

    const referenceFeet =
      convertReferenceToFeet();

    if (
      referenceFeet === null
    ) {
      setMessage(
        "Please enter a valid actual length for the known reference object."
      );
      return;
    }

    const referencePixels =
      distance(
        referencePoints[0],
        referencePoints[1]
      );

    const measurementPixels =
      distance(
        points[0],
        points[1]
      );

    if (
      referencePixels <= 0
    ) {
      setMessage(
        "Invalid reference points."
      );
      return;
    }

    const result =
      (measurementPixels /
        referencePixels) *
      referenceFeet;

    setCalculatedFeet(
      result
    );

    setMessage(
      `${measurementLabel} calculated. Review the result before using it.`
    );
  };

  /* =========================================================
     CANVAS CLICK
  ========================================================= */

  const handleCanvasClick = (
    event: MouseEvent<HTMLCanvasElement>
  ) => {
    if (!imageLoaded) {
      return;
    }

    const canvas =
      canvasRef.current;

    if (!canvas) {
      return;
    }

    const rect =
      canvas.getBoundingClientRect();

    const scaleX =
      canvas.width /
      rect.width;

    const scaleY =
      canvas.height /
      rect.height;

    const rawPoint: Point = {
      x:
        (event.clientX -
          rect.left) *
        scaleX,

      y:
        (event.clientY -
          rect.top) *
        scaleY,
    };

    /* -----------------------------------------------------
       REFERENCE MODE
    ----------------------------------------------------- */

    if (
      mode === "REFERENCE"
    ) {
      if (
        referencePoints.length >= 2
      ) {
        setReferencePoints([
          rawPoint,
        ]);

        setMeasurementPoints(
          []
        );

        setCalculatedFeet(
          null
        );

        setMessage(
          "Reference point 1 selected. Click reference point 2."
        );

        return;
      }

      let point = rawPoint;

      if (
        referencePoints.length === 1
      ) {
        point =
          applyDirectionConstraint(
            referencePoints[0],
            rawPoint
          );
      }

      const nextPoints = [
        ...referencePoints,
        point,
      ];

      setReferencePoints(
        nextPoints
      );

      if (
        nextPoints.length === 1
      ) {
        setMessage(
          "Reference point 1 selected. Click the other end of the reference object."
        );
      }

      if (
        nextPoints.length === 2
      ) {
        setMessage(
          "Reference selected. Confirm the actual reference length, then select the object measurement points."
        );
      }

      return;
    }

    /* -----------------------------------------------------
       MEASUREMENT MODE
    ----------------------------------------------------- */

    if (
      mode === "MEASURE"
    ) {
      if (
        measurementPoints.length >=
        2
      ) {
        setMeasurementPoints([
          rawPoint,
        ]);

        setCalculatedFeet(
          null
        );

        setMessage(
          `${measurementLabel} point 1 selected. Click point 2.`
        );

        return;
      }

      let point = rawPoint;

      if (
        measurementPoints.length === 1
      ) {
        point =
          applyDirectionConstraint(
            measurementPoints[0],
            rawPoint
          );
      }

      const nextPoints = [
        ...measurementPoints,
        point,
      ];

      setMeasurementPoints(
        nextPoints
      );

      if (
        nextPoints.length === 1
      ) {
        setMessage(
          `${measurementLabel} point 1 selected. Click point 2.`
        );
      }

      if (
        nextPoints.length === 2
      ) {
        calculateMeasurement(
          nextPoints
        );
      }
    }
  };

  /* =========================================================
     RESET / START
  ========================================================= */

  const resetReference = () => {
    setReferencePoints([]);
    setMeasurementPoints([]);
    setCalculatedFeet(null);
    setMode("REFERENCE");

    setMessage(
      "Reference reset. Select the two ends of the known reference object."
    );
  };

  const resetMeasurement = () => {
    setMeasurementPoints([]);
    setCalculatedFeet(null);
    setMode("MEASURE");

    setMessage(
      `Select the first ${measurementLabel} point.`
    );
  };

  const startIdolMeasurement = () => {
    if (!imageLoaded) {
      setMessage(
        "Capture or upload a photograph first."
      );
      return;
    }

    if (
      referencePoints.length !== 2
    ) {
      setMessage(
        "Select the two reference points first."
      );
      return;
    }

    if (
      convertReferenceToFeet() ===
      null
    ) {
      setMessage(
        "Enter the actual reference length first."
      );
      return;
    }

    setMeasurementPoints([]);
    setCalculatedFeet(null);
    setMode("MEASURE");

    setMessage(
      `Click the first ${measurementLabel} point.`
    );
  };

  /* =========================================================
     CLOSE / CLEANUP
  ========================================================= */

  const closeTool = () => {
    stopCamera();
    onClose();
  };

  useEffect(() => {
    return () => {
      const stream =
        streamRef.current;

      if (stream) {
        stream
          .getTracks()
          .forEach((track) => {
            track.stop();
          });
      }
    };
  }, []);

  /* =========================================================
     UI
  ========================================================= */

  return (
    <div className="fixed inset-0 z-50 bg-black/60 overflow-y-auto">

      <div className="max-w-7xl mx-auto my-5 bg-white rounded-2xl shadow-2xl overflow-hidden">

        {/* HEADER */}

        <header className="bg-[#17365D] text-white px-6 py-5 flex justify-between items-center">

          <div>
            <p className="text-xs tracking-widest text-blue-200">
              DIGITAL MEASUREMENT TOOL
            </p>

            <h2 className="text-xl font-bold">
              Measure Object {measurementLabel}
            </h2>
          </div>

          <button
            type="button"
            onClick={closeTool}
            className="border border-white/30 hover:bg-white/10 rounded-lg px-4 py-2"
          >
            ✕ Close
          </button>

        </header>

        <div className="p-6">

          {/* GUIDANCE */}

          <div className="bg-amber-50 border border-amber-200 text-amber-900 rounded-xl p-4 mb-6">

            <p className="font-bold">
              Measurement Guidance
            </p>

            <p className="text-sm mt-1">
              This tool can measure a straight-line distance
              horizontally, vertically, diagonally, upward,
              downward or sideways. For accurate scale, keep
              the known reference object approximately on the
              same plane and at the same distance from the
              camera as the object being measured.
            </p>

          </div>

          <div className="grid lg:grid-cols-3 gap-6">

            {/* LEFT PANEL */}

            <div>

              {/* STEP 1 — CAMERA / PHOTO */}

              <section className="border border-slate-200 rounded-xl p-5 mb-4">

                <div className="flex items-center gap-3 mb-4">

                  <div className="w-8 h-8 rounded-full bg-[#17365D] text-white flex items-center justify-center font-bold">
                    1
                  </div>

                  <h3 className="font-bold text-slate-800">
                    Camera / Photograph
                  </h3>

                </div>

                {!cameraOpen && (
                  <button
                    type="button"
                    onClick={() =>
                      openCamera()
                    }
                    disabled={
                      cameraLoading
                    }
                    className="w-full bg-[#17365D] hover:bg-[#244d7e] disabled:bg-slate-300 text-white font-semibold px-4 py-3 rounded-lg"
                  >
                    {cameraLoading
                      ? "Opening Camera..."
                      : "📷 Open Camera"}
                  </button>
                )}

                {cameraDevices.length >
                  1 && (
                  <div className="mt-3">

                    <label className="block text-sm font-semibold text-slate-700 mb-2">
                      Select Camera
                    </label>

                    <select
                      value={
                        selectedCameraId
                      }
                      onChange={(
                        event
                      ) =>
                        switchCamera(
                          event.target
                            .value
                        )
                      }
                      className="w-full border border-slate-300 rounded-lg px-3 py-3"
                    >
                      {cameraDevices.map(
                        (
                          camera
                        ) => (
                          <option
                            key={
                              camera.deviceId
                            }
                            value={
                              camera.deviceId
                            }
                          >
                            {
                              camera.label
                            }
                          </option>
                        )
                      )}
                    </select>

                  </div>
                )}

                {cameraOpen && (
                  <div className="mt-4">

                    {/* LIVE CAMERA WITH IPHONE-LIKE POINTER */}

                    <div className="relative bg-black rounded-xl overflow-hidden">

                      <video
                        ref={videoRef}
                        autoPlay
                        playsInline
                        muted
                        className="w-full h-auto bg-black"
                        onLoadedMetadata={() => {
                          const video =
                            videoRef.current;

                          if (video) {
                            video
                              .play()
                              .catch(
                                (
                                  error
                                ) => {
                                  console.error(
                                    "Video play failed:",
                                    error
                                  );
                                }
                              );
                          }
                        }}
                      />

                      {/* CENTER POINTER / CROSSHAIR */}

                      <div className="pointer-events-none absolute inset-0 flex items-center justify-center">

                        <div className="relative w-20 h-20">

                          <div className="absolute left-1/2 top-0 bottom-0 w-[2px] bg-yellow-300 -translate-x-1/2 opacity-90" />

                          <div className="absolute top-1/2 left-0 right-0 h-[2px] bg-yellow-300 -translate-y-1/2 opacity-90" />

                          <div className="absolute inset-3 rounded-full border-2 border-yellow-300 shadow-lg" />

                          <div className="absolute left-1/2 top-1/2 w-3 h-3 rounded-full bg-yellow-300 -translate-x-1/2 -translate-y-1/2" />

                        </div>

                      </div>

                      <div className="pointer-events-none absolute bottom-3 left-1/2 -translate-x-1/2 bg-black/60 text-yellow-200 text-xs px-3 py-1 rounded-full">
                        Align object with centre pointer
                      </div>

                    </div>

                    <div className="grid grid-cols-2 gap-2 mt-3">

                      <button
                        type="button"
                        onClick={
                          captureCameraFrame
                        }
                        className="bg-green-700 hover:bg-green-800 text-white font-semibold px-3 py-3 rounded-lg"
                      >
                        📸 Capture Frame
                      </button>

                      <button
                        type="button"
                        onClick={
                          stopCamera
                        }
                        className="border border-red-300 text-red-700 hover:bg-red-50 px-3 py-3 rounded-lg"
                      >
                        Stop Camera
                      </button>

                    </div>

                  </div>
                )}

                <div className="my-4 flex items-center gap-3">

                  <div className="h-px bg-slate-200 flex-1" />

                  <span className="text-xs text-slate-400">
                    OR
                  </span>

                  <div className="h-px bg-slate-200 flex-1" />

                </div>

                <label className="block text-sm font-semibold text-slate-700 mb-2">
                  Upload / Take Photograph
                </label>

                <input
                  type="file"
                  accept="image/*"
                  capture="environment"
                  onChange={
                    handleImageUpload
                  }
                  className="w-full text-sm"
                />

              </section>

              {/* STEP 2 — DIRECTION */}

              <section className="border border-slate-200 rounded-xl p-5 mb-4">

                <div className="flex items-center gap-3 mb-4">

                  <div className="w-8 h-8 rounded-full bg-[#17365D] text-white flex items-center justify-center font-bold">
                    2
                  </div>

                  <h3 className="font-bold text-slate-800">
                    Measurement Direction
                  </h3>

                </div>

                <select
                  value={directionMode}
                  onChange={(event) => {
                    setDirectionMode(
                      event.target
                        .value as DirectionMode
                    );

                    setMeasurementPoints([]);
                    setCalculatedFeet(null);
                  }}
                  className="w-full border border-slate-300 rounded-lg px-4 py-3"
                >
                  <option value="FREE">
                    Free Direction — any angle
                  </option>

                  <option value="HORIZONTAL">
                    Horizontal Only
                  </option>

                  <option value="VERTICAL">
                    Vertical Only
                  </option>
                </select>

                <p className="text-xs text-slate-500 mt-3">
                  Free Direction supports horizontal, vertical,
                  diagonal, upward, downward and sideways
                  measurements.
                </p>

              </section>

              {/* STEP 3 — KNOWN REFERENCE */}

              <section className="border border-slate-200 rounded-xl p-5 mb-4">

                <div className="flex items-center gap-3 mb-4">

                  <div className="w-8 h-8 rounded-full bg-[#17365D] text-white flex items-center justify-center font-bold">
                    3
                  </div>

                  <h3 className="font-bold text-slate-800">
                    Known Reference
                  </h3>

                </div>

                <label className="block text-sm font-semibold text-slate-700 mb-2">
                  Actual Reference Length
                </label>

                <input
                  type="number"
                  value={
                    referenceLength
                  }
                  onChange={(
                    event
                  ) => {
                    setReferenceLength(
                      event.target
                        .value
                    );

                    setCalculatedFeet(
                      null
                    );
                  }}
                  min="0"
                  step="0.01"
                  placeholder="Example: 3"
                  className="w-full border border-slate-300 rounded-lg px-4 py-3 mb-3"
                />

                <label className="block text-sm font-semibold text-slate-700 mb-2">
                  Unit
                </label>

                <select
                  value={
                    referenceUnit
                  }
                  onChange={(
                    event
                  ) => {
                    setReferenceUnit(
                      event.target
                        .value as ReferenceUnit
                    );

                    setCalculatedFeet(
                      null
                    );
                  }}
                  className="w-full border border-slate-300 rounded-lg px-4 py-3"
                >
                  <option value="FT">
                    Feet
                  </option>

                  <option value="INCH">
                    Inches
                  </option>

                  <option value="CM">
                    Centimetres
                  </option>
                </select>

                <button
                  type="button"
                  onClick={() => {
                    if (
                      !imageLoaded
                    ) {
                      setMessage(
                        "Capture or upload a photograph first."
                      );

                      return;
                    }

                    setReferencePoints(
                      []
                    );

                    setMeasurementPoints(
                      []
                    );

                    setCalculatedFeet(
                      null
                    );

                    setMode(
                      "REFERENCE"
                    );

                    setMessage(
                      "Reference mode active. Click reference point 1."
                    );
                  }}
                  className={`w-full mt-4 px-4 py-3 rounded-lg font-semibold ${
                    mode ===
                    "REFERENCE"
                      ? "bg-blue-700 text-white"
                      : "bg-slate-100 text-slate-700"
                  }`}
                >
                  Select Reference Points
                </button>

                <button
                  type="button"
                  onClick={
                    resetReference
                  }
                  className="w-full mt-2 border border-slate-300 rounded-lg px-4 py-2"
                >
                  Reset Reference
                </button>

              </section>

              {/* STEP 4 — OBJECT MEASUREMENT */}

              <section className="border border-slate-200 rounded-xl p-5">

                <div className="flex items-center gap-3 mb-4">

                  <div className="w-8 h-8 rounded-full bg-[#17365D] text-white flex items-center justify-center font-bold">
                    4
                  </div>

                  <h3 className="font-bold text-slate-800">
                    Object {measurementLabel}
                  </h3>

                </div>

                <button
                  type="button"
                  onClick={
                    startIdolMeasurement
                  }
                  className={`w-full px-4 py-3 rounded-lg font-semibold ${
                    mode ===
                    "MEASURE"
                      ? "bg-green-700 text-white"
                      : "bg-slate-100 text-slate-700"
                  }`}
                >
                  Select {measurementLabel} Points
                </button>

                <button
                  type="button"
                  onClick={
                    resetMeasurement
                  }
                  className="w-full mt-2 border border-slate-300 rounded-lg px-4 py-2"
                >
                  Reset Measurement
                </button>

              </section>

            </div>

            {/* RIGHT PANEL */}

            <div className="lg:col-span-2">

              <section className="border border-slate-200 rounded-xl p-4">

                <div
                  className={`rounded-lg px-4 py-3 mb-4 text-sm border ${
                    mode ===
                    "REFERENCE"
                      ? "bg-blue-50 border-blue-200 text-blue-800"
                      : "bg-green-50 border-green-200 text-green-800"
                  }`}
                >
                  <strong>
                    {mode ===
                    "REFERENCE"
                      ? "Reference Mode: "
                      : "Measurement Mode: "}
                  </strong>

                  {message}
                </div>

                <div className="flex gap-5 flex-wrap mb-4 text-sm">

                  <div className="flex items-center gap-2">
                    <span className="w-4 h-4 bg-blue-600 rounded-full" />
                    Reference
                  </div>

                  <div className="flex items-center gap-2">
                    <span className="w-4 h-4 bg-green-600 rounded-full" />
                    Object {measurementLabel}
                  </div>

                </div>

                <div className="bg-slate-900 rounded-xl min-h-[400px] overflow-auto flex items-center justify-center">

                  <canvas
                    ref={canvasRef}
                    onClick={
                      handleCanvasClick
                    }
                    className={`max-w-full h-auto block ${
                      imageLoaded
                        ? "cursor-crosshair"
                        : ""
                    }`}
                  />

                  {!imageLoaded && (
                    <div className="text-center text-slate-400 py-24 px-5">

                      <div className="text-5xl">
                        📷
                      </div>

                      <p className="font-semibold mt-4">
                        No Captured Photograph
                      </p>

                      <p className="text-sm mt-2">
                        Open the camera and capture a frame,
                        or upload an existing photograph.
                      </p>

                    </div>
                  )}

                </div>

              </section>

              {calculatedFeet !==
                null && (
                <section className="mt-5 bg-green-50 border border-green-300 rounded-xl p-6">

                  <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-5">

                    <div>

                      <p className="text-sm font-semibold text-green-700">
                        Calculated {measurementLabel}
                      </p>

                      <p className="text-4xl font-bold text-green-900 mt-1">
                        {calculatedFeet.toFixed(
                          2
                        )}{" "}
                        ft
                      </p>

                      <p className="text-sm text-green-700 mt-2">
                        Approximately{" "}
                        {(
                          calculatedFeet *
                          12
                        ).toFixed(
                          1
                        )}{" "}
                        inches
                      </p>

                    </div>

                    <button
                      type="button"
                      onClick={() =>
                        onUseMeasurement(
                          Number(
                            calculatedFeet.toFixed(
                              2
                            )
                          )
                        )
                      }
                      className="bg-green-700 hover:bg-green-800 text-white font-semibold px-7 py-3 rounded-lg"
                    >
                      ✓ Use This Measurement
                    </button>

                  </div>

                </section>
              )}

              <section className="mt-5 bg-slate-50 border border-slate-200 rounded-xl p-4">

                <p className="font-semibold text-slate-700 text-sm">
                  Supported Directions
                </p>

                <p className="text-xs text-slate-500 mt-2">
                  Free Direction can calculate a straight-line
                  measurement from any selected start point to
                  any selected end point — horizontal, vertical,
                  diagonal, upward, downward, left or right.
                </p>

              </section>

            </div>

          </div>

        </div>

      </div>

    </div>
  );
}

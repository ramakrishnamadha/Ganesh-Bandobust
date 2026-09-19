"use client";

import { MapContainer, Marker, Popup, TileLayer } from "react-leaflet";
import L from "leaflet";

type Officer = {
  userId: string;
  userName: string;
  rank: string | null;
  role: string | null;
  policeStationCode: string | null;
  sectorCode: string | null;
  latitude: number;
  longitude: number;
  accuracy: number | null;
  batteryLevel: number | null;
  activityStatus: string | null;
  activeGpid: string | null;
  liveStatus: "ACTIVE" | "STALE" | "OFFLINE";
  capturedAt: string;
  lastSeenAt: string;
};

type LiveTrackingMapProps = {
  officers: Officer[];
};

const officerIcon = L.divIcon({
  className: "",
  html: `
    <div
      style="
        width: 22px;
        height: 22px;
        border-radius: 9999px;
        background: #17365D;
        border: 3px solid white;
        box-shadow: 0 1px 6px rgba(0,0,0,0.35);
      "
    ></div>
  `,
  iconSize: [22, 22],
  iconAnchor: [11, 11],
});

export default function LiveTrackingMap({
  officers,
}: LiveTrackingMapProps) {
  const firstOfficer = officers[0];

  const center: [number, number] = firstOfficer
    ? [firstOfficer.latitude, firstOfficer.longitude]
    : [17.385, 78.4867];

  return (
    <div className="h-[620px] w-full overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
      <MapContainer
        center={center}
        zoom={13}
        scrollWheelZoom
        className="h-full w-full"
      >
        <TileLayer
          attribution="&copy; OpenStreetMap contributors"
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />

        {officers.map((officer) => (
          <Marker
            key={officer.userId}
            position={[officer.latitude, officer.longitude]}
            icon={officerIcon}
          >
            <Popup>
              <div className="min-w-[220px]">
                <div className="font-bold">
                  {officer.rank
                    ? `${officer.rank} ${officer.userName}`
                    : officer.userName}
                </div>

                <div className="mt-1 text-sm">
                  {officer.role ?? "-"}
                </div>

                <div className="mt-2 text-sm">
                  PS: {officer.policeStationCode ?? "-"}
                </div>

                <div className="text-sm">
                  Sector: {officer.sectorCode ?? "-"}
                </div>

                <div className="mt-2 text-sm">
                  Status: {officer.liveStatus}
                </div>

                <div className="text-sm">
                  Activity: {officer.activityStatus ?? "-"}
                </div>

                <div className="text-sm">
                  GPID: {officer.activeGpid ?? "-"}
                </div>

                <div className="mt-2 text-sm">
                  Accuracy:{" "}
                  {officer.accuracy !== null
                    ? `${officer.accuracy.toFixed(1)} m`
                    : "-"}
                </div>

                <div className="text-sm">
                  Battery:{" "}
                  {officer.batteryLevel !== null
                    ? `${officer.batteryLevel}%`
                    : "-"}
                </div>

                <div className="mt-2 text-xs text-slate-500">
                  Last seen:{" "}
                  {new Date(officer.lastSeenAt).toLocaleString()}
                </div>
              </div>
            </Popup>
          </Marker>
        ))}
      </MapContainer>
    </div>
  );
}
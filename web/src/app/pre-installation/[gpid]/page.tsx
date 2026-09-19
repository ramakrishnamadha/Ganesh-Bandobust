"use client";

import { useEffect, useState, type ReactNode } from "react";
import { useParams, useRouter } from "next/navigation";

type JsonObject = Record<string, unknown>;

type VerificationRecord = {
  id: number;
  gpid: string;
  applicationId?: string | null;
  locationResult?: JsonObject | null;
  mandapResult?: JsonObject | null;
  idolResult?: JsonObject | null;
  routeResult?: JsonObject | null;
  securityResult?: JsonObject | null;
  organizerResult?: JsonObject | null;
  interDepartmentalResult?: JsonObject | null;
  permissionShoReviewResult?: JsonObject | null;
  verificationStatus?: string | null;
  submittedAt?: string | null;
  updatedAt?: string | null;
};


type GaneshApplicationRecord = {
  unique_id?: string;
  ref_no?: string;
  name?: string;
  association?: string;
  mobile_no?: string;
  address?: string;
  h_no?: string;
  street?: string;
  town?: string;
  pin?: string | number;
  ps_name?: string;
  division_name?: string;
  zone_name?: string;
  dist_name?: string;
  status?: string;
  idol_area_type?: string;
  idol_type?: string;
  idol_height?: string | number;
  instal_from_date?: string;
  instal_to_date?: string;
  immr_date?: string;
  riv_name?: string;
};

type ModuleKey =
  | "locationResult"
  | "mandapResult"
  | "idolResult"
  | "routeResult"
  | "securityResult"
  | "organizerResult"
  | "interDepartmentalResult"
  | "permissionShoReviewResult";

type ModuleDefinition = {
  key: ModuleKey;
  number: number;
  title: string;
  description: string;
};

const MODULES: ModuleDefinition[] = [
  {
    key: "locationResult",
    number: 1,
    title: "Location-Based Verification",
    description:
      "Location verification, geo-location, jurisdiction, disputed land and sensitivity.",
  },
  {
    key: "mandapResult",
    number: 2,
    title: "Mandap-Based Verification",
    description:
      "Mandap installation, structural stability, obstruction, electrical risks, height and evidence.",
  },
  {
    key: "idolResult",
    number: 3,
    title: "Idol-Based Verification",
    description:
      "Idol installation, material, photo/GPS, measurements and base/platform safety.",
  },
  {
    key: "routeResult",
    number: 4,
    title: "Route-Based Verification",
    description:
      "Installation/procession route, route stretches, geo-tagged issues and departmental follow-up.",
  },
  {
    key: "securityResult",
    number: 5,
    title: "Security-Based Verification",
    description:
      "Security, CCTV, fire safety, emergency access, lighting and public-address arrangements.",
  },
  {
    key: "organizerResult",
    number: 6,
    title: "Organizer-Based Verification",
    description:
      "Organizer/member details, roles, contact verification and confidential adverse information.",
  },
  {
    key: "interDepartmentalResult",
    number: 7,
    title: "Inter-Departmental Coordination / NOCs",
    description:
      "Auto-identified requirements, coordination/NOC status, additional coordination and unresolved issues.",
  },
  {
    key: "permissionShoReviewResult",
    number: 8,
    title: "Permission / SHO Review",
    description:
      "Verification summary, adverse findings, SHO review and final permission recommendation.",
  },
];

function obj(value: unknown): JsonObject | null {
  return value && typeof value === "object" && !Array.isArray(value)
    ? (value as JsonObject)
    : null;
}

function arr(value: unknown): unknown[] {
  return Array.isArray(value) ? value : [];
}

function text(value: unknown): string {
  if (value === null || value === undefined) return "";
  if (typeof value === "boolean") return value ? "YES" : "NO";
  const valueText = String(value).trim();
  return valueText.toLowerCase() === "null" ? "" : valueText;
}

function yes(value: unknown): boolean {
  return text(value).toUpperCase() === "YES";
}

function no(value: unknown): boolean {
  return text(value).toUpperCase() === "NO";
}

function label(value: string): string {
  return value
    .replace(/([a-z])([A-Z])/g, "$1 $2")
    .replace(/_/g, " ")
    .replace(/\b\w/g, (m) => m.toUpperCase());
}

function dateText(value: unknown): string {
  const raw = text(value);
  if (!raw) return "-";
  const d = new Date(raw);
  return Number.isNaN(d.getTime()) ? raw : d.toLocaleString("en-IN");
}

function Field({
  label: fieldLabel,
  value,
  status = false,
  warning = false,
}: {
  label: string;
  value: unknown;
  status?: boolean;
  warning?: boolean;
}) {
  const valueText = text(value);
  const upper = valueText.toUpperCase();

  return (
    <div
      className={`rounded-lg border p-4 ${
        warning ? "border-amber-200 bg-amber-50" : "border-slate-200 bg-white"
      }`}
    >
      <p className="mb-2 text-xs font-semibold text-slate-500">{fieldLabel}</p>

      {status && (upper === "YES" || upper === "NO" || upper === "NOT APPLICABLE") ? (
        <span
          className={`inline-flex rounded-full px-3 py-1 text-xs font-bold ${
            upper === "YES"
              ? "bg-green-50 text-green-700"
              : upper === "NO"
                ? "bg-red-50 text-red-700"
                : "bg-slate-100 text-slate-700"
          }`}
        >
          {upper}
        </span>
      ) : (
        <p className={`break-words font-semibold ${warning ? "text-amber-900" : "text-slate-800"}`}>
          {valueText || "-"}
        </p>
      )}
    </div>
  );
}

function Section({
  eyebrow,
  title,
  children,
  tone = "normal",
}: {
  eyebrow?: string;
  title: string;
  children: ReactNode;
  tone?: "normal" | "warning" | "confidential";
}) {
  const classes =
    tone === "confidential"
      ? "border-red-300 bg-red-50"
      : tone === "warning"
        ? "border-amber-200 bg-amber-50"
        : "border-slate-200 bg-white";

  return (
    <section className={`rounded-xl border p-5 ${classes}`}>
      {eyebrow && (
        <p
          className={`text-xs font-bold tracking-widest ${
            tone === "confidential" ? "text-red-700" : "text-slate-400"
          }`}
        >
          {eyebrow}
        </p>
      )}
      <h4
        className={`mt-1 font-bold ${
          tone === "confidential" ? "text-red-900" : "text-[#17365D]"
        }`}
      >
        {title}
      </h4>
      <div className="mt-4">{children}</div>
    </section>
  );
}

function RawValue({ value, level = 0 }: { value: unknown; level?: number }) {
  if (value === null || value === undefined) {
    return <span className="text-slate-400">-</span>;
  }

  if (typeof value !== "object") {
    const valueText = text(value);
    return (
      <span
        className={
          valueText.toUpperCase() === "NO"
            ? "font-semibold text-red-700"
            : valueText.toUpperCase() === "YES"
              ? "font-semibold text-green-700"
              : "text-slate-800"
        }
      >
        {valueText || "-"}
      </span>
    );
  }

  if (Array.isArray(value)) {
    if (!value.length) return <span className="text-slate-400">No entries</span>;
    return (
      <div className="space-y-3">
        {value.map((item, index) => (
          <div key={index} className="rounded-lg border border-slate-200 bg-white p-3">
            <p className="mb-2 text-xs font-bold text-slate-400">ITEM {index + 1}</p>
            <RawValue value={item} level={level + 1} />
          </div>
        ))}
      </div>
    );
  }

  const entries = Object.entries(value as JsonObject);
  return (
    <div className={level === 0 ? "grid gap-3 md:grid-cols-2" : "space-y-3"}>
      {entries.map(([key, child]) => (
        <div
          key={key}
          className={`rounded-lg border border-slate-200 bg-slate-50 p-3 ${
            typeof child === "object" && child !== null ? "md:col-span-2" : ""
          }`}
        >
          <p className="mb-1 text-xs font-semibold text-slate-500">{label(key)}</p>
          <RawValue value={child} level={level + 1} />
        </div>
      ))}
    </div>
  );
}

function RawPayload({
  name,
  result,
  confidential = false,
}: {
  name: string;
  result: JsonObject;
  confidential?: boolean;
}) {
  return (
    <Section
      eyebrow={confidential ? "CONFIDENTIAL · OFFICIAL USE ONLY" : "COMPLETE MOBILE SUBMISSION"}
      title={`Full ${name} Payload`}
      tone={confidential ? "confidential" : "normal"}
    >
      <p className="mb-4 text-sm text-slate-600">
        Every field received from the Mobile application is retained below for supervisory visibility.
      </p>
      <RawValue value={result} />
    </Section>
  );
}

function fields(result: JsonObject, definitions: Array<[string, string, boolean?, boolean?]>) {
  return (
    <div className="grid gap-3 md:grid-cols-2 lg:grid-cols-4">
      {definitions.map(([key, fieldLabel, status, warning]) => (
        <Field
          key={key}
          label={fieldLabel}
          value={result[key]}
          status={status}
          warning={warning}
        />
      ))}
    </div>
  );
}

/* MODULE 1 */

function LocationView({
  result,
  parentGpid,
  parentApplicationId,
}: {
  result: JsonObject;
  parentGpid: string;
  parentApplicationId?: string | null;
}) {
  const displayResult: JsonObject = {
    ...result,
    gpid: text(result.gpid) || parentGpid,
    applicationId: text(result.applicationId) || parentApplicationId || "",
  };

  const original = obj(result.originalGeoLocation);
  const current = obj(result.currentVerifiedGeoLocation);

  return (
    <div className="space-y-5">
      <Section eyebrow="MODULE 1" title="Location-Based Verification">
        {fields(displayResult, [
          ["gpid", "GPID"],
          ["applicationId", "Application ID"],
          ["locationVerified", "Location Verified?", true, no(result.locationVerified)],
          ["remarks", "Location Verification Remarks"],
          ["locationChanged", "Installation Location Changed?", true, yes(result.locationChanged)],
          ["samePoliceStation", "Within Same Police Station?", true, no(result.samePoliceStation)],
          ["sector", "Sector"],
          ["commissionerate", "Commissionerate"],
          ["policeStation", "Police Station"],
          ["disputedLand", "Disputed Land?", true, yes(result.disputedLand)],
          ["disputedLandRemarks", "Disputed Land Remarks"],
          ["sensitivity", "Sensitivity", false, ["MEDIUM", "HIGH"].includes(text(result.sensitivity).toUpperCase())],
          ["sensitivityRemarks", "Sensitivity Remarks"],
        ])}
      </Section>

      <Section title="Original and Current Verified Geo-Location">
        <div className="grid gap-4 lg:grid-cols-2">
          <div className="rounded-xl border border-slate-200 bg-slate-50 p-4">
            <h5 className="mb-3 font-bold text-slate-700">Original GPID Geo-Location</h5>
            <div className="grid gap-3 sm:grid-cols-2">
              <Field label="Latitude" value={original?.latitude} />
              <Field label="Longitude" value={original?.longitude} />
            </div>
          </div>
          <div className="rounded-xl border border-slate-200 bg-slate-50 p-4">
            <h5 className="mb-3 font-bold text-slate-700">Current Verified Geo-Location</h5>
            <div className="grid gap-3 sm:grid-cols-2">
              <Field label="Latitude" value={current?.latitude} />
              <Field label="Longitude" value={current?.longitude} />
              <Field label="GPS Accuracy" value={current?.accuracy ?? current?.gpsAccuracy} />
              <Field label="Captured At" value={dateText(current?.capturedAt)} />
            </div>
          </div>
        </div>
        <div className="mt-3">
          <Field label="Verified At" value={dateText(result.verifiedAt)} />
        </div>
      </Section>

      <RawPayload name="Location Verification" result={result} />
    </div>
  );
}

/* MODULE 2 */

function MandapView({
  result,
  parentGpid,
  parentApplicationId,
}: {
  result: JsonObject;
  parentGpid: string;
  parentApplicationId?: string | null;
}) {
  const displayResult: JsonObject = {
    ...result,
    gpid: text(result.gpid) || parentGpid,
    applicationId: text(result.applicationId) || parentApplicationId || "",
  };

  const evidence = obj(result.mandapPhotoEvidence);

  return (
    <div className="space-y-5">
      <Section eyebrow="MODULE 2" title="Mandap-Based Verification">
        {fields(displayResult, [
          ["gpid", "GPID"],
          ["applicationId", "Application ID"],
          ["mandapInstalled", "Mandap Installed?", true, no(result.mandapInstalled)],
          ["mandapNotInstalledRemarks", "Not Installed Remarks"],
          ["structuralStability", "Structural Stability?", true, no(result.structuralStability)],
          ["structuralRemarks", "Structural Remarks"],
          ["roadObstruction", "Road Obstruction?", true, yes(result.roadObstruction)],
          ["obstructionType", "Obstruction Type"],
          ["otherObstruction", "Other Obstruction"],
          ["trafficImpact", "Traffic Impact"],
          ["roadWidth", "Available Road Width"],
          ["emergencyAccess", "Emergency Vehicle Access?", true, no(result.emergencyAccess)],
          ["emergencyRemarks", "Emergency Access Remarks"],
          ["overheadWires", "Overhead Wires Present?", true, yes(result.overheadWires)],
          ["overheadWiresRisk", "Overhead Wire Safety Risk?", true, yes(result.overheadWiresRisk)],
          ["overheadWiresPhotoPath", "Overhead Wire Evidence"],
          ["overheadWiresRemarks", "Overhead Wire Remarks"],
          ["electricalHazard", "Electrical Hazard Present?", true, yes(result.electricalHazard)],
          ["electricalHazardType", "Electrical Hazard Type"],
          ["otherElectricalHazard", "Other Electrical Hazard"],
          ["electricalHazardRisk", "Electrical Hazard Safety Risk?", true, yes(result.electricalHazardRisk)],
          ["electricalHazardPhotoPath", "Electrical Hazard Evidence"],
          ["electricalHazardRemarks", "Electrical Hazard Remarks"],
          ["declaredMandapHeight", "Declared Mandap Height"],
          ["mandapHeightVerified", "Mandap Height Matches?", true, no(result.mandapHeightVerified)],
          ["actualMandapHeight", "Actual Mandap Height"],
          ["mandapHeightRemarks", "Mandap Height Remarks"],
          ["mandapPhotoPath", "Mandap Photo Path"],
          ["officerConfirmation", "Officer Confirmation", true],
        ])}
      </Section>

      <Section title="Mandap Photo GPS Evidence">
        <div className="grid gap-3 md:grid-cols-2 lg:grid-cols-4">
          <Field label="Latitude" value={evidence?.latitude} />
          <Field label="Longitude" value={evidence?.longitude} />
          <Field label="GPS Accuracy" value={evidence?.accuracy} />
          <Field label="Captured At" value={dateText(evidence?.capturedAt)} />
        </div>
        <div className="mt-3">
          <Field label="Verified At" value={dateText(result.verifiedAt)} />
        </div>
      </Section>

      <RawPayload name="Mandap Verification" result={result} />
    </div>
  );
}

/* MODULE 3 */

function MeasurementBox({ title, value }: { title: string; value: unknown }) {
  const measurement = obj(value);
  return (
    <div className="rounded-xl border border-slate-200 bg-slate-50 p-4">
      <h5 className="mb-3 font-bold text-slate-700">{title}</h5>
      {measurement ? <RawValue value={measurement} /> : <p className="text-sm text-slate-400">Not available</p>}
    </div>
  );
}

function IdolView({ result }: { result: JsonObject }) {
  return (
    <div className="space-y-5">
      <Section eyebrow="MODULE 3" title="Idol-Based Verification">
        {fields(result, [
          ["gpid", "GPID"],
          ["applicationId", "Application ID"],
          ["idolInstalled", "Idol Installed?", true, no(result.idolInstalled)],
          ["idolBroughtFrom", "Idol Brought From"],
          ["idolConstructedAtLocation", "Constructed at Installation Location?", true, yes(result.idolConstructedAtLocation)],
          ["idolMaterial", "Idol Material"],
          ["idolPhotoPath", "Idol Photo Path"],
          ["idolLatitude", "Photo Latitude"],
          ["idolLongitude", "Photo Longitude"],
          ["idolGpsAccuracy", "Photo GPS Accuracy"],
          ["idolPhotoTakenAt", "Photo Taken At"],
          ["declaredIdolHeight", "Declared Idol Height"],
          ["heightMatches", "Height Matches?", true, no(result.heightMatches)],
          ["heightRecordMode", "Height Record Mode"],
          ["actualHeightFeet", "Actual Height Feet"],
          ["actualHeightInches", "Actual Height Inches"],
          ["heightRemarks", "Height Remarks"],
          ["declaredIdolWidth", "Declared Idol Width"],
          ["widthMatches", "Width Matches?", true, no(result.widthMatches)],
          ["widthRecordMode", "Width Record Mode"],
          ["idolWidthFeet", "Actual Width Feet"],
          ["idolWidthInches", "Actual Width Inches"],
          ["basePlatformSafe", "Base / Platform Safe?", true, no(result.basePlatformSafe)],
          ["baseSafetyRemarks", "Base Safety Remarks"],
          ["officerConfirmed", "Officer Confirmation", true],
        ])}
      </Section>

      <Section title="Digital Measurement Evidence">
        <div className="space-y-4">
          <MeasurementBox title="Height Measurement" value={result.heightMeasurement} />
          <MeasurementBox title="Width Measurement" value={result.widthMeasurement} />
        </div>
        <div className="mt-3">
          <Field label="Verified At" value={dateText(result.verifiedAt)} />
        </div>
      </Section>

      <RawPayload name="Idol Verification" result={result} />
    </div>
  );
}

/* MODULE 4 */

function RouteIssue({ issue, index }: { issue: JsonObject; index: number }) {
  return (
    <div className={`rounded-xl border p-4 ${yes(issue.noticed) ? "border-amber-200 bg-amber-50" : "border-slate-200 bg-white"}`}>
      <p className="text-xs font-bold tracking-widest text-slate-400">
        POINT {text(issue.pointNo) || index + 3}
      </p>
      <h6 className="mt-1 font-bold text-slate-800">{text(issue.title) || "Route Issue"}</h6>
      <div className="mt-3 grid gap-3 md:grid-cols-2 lg:grid-cols-4">
        {[
          ["noticed", "Issue Noticed?", true],
          ["routeImpact", "Route Impact?", true],
          ["obstructionType", "Obstruction Type"],
          ["obstructionOther", "Other Obstruction"],
          ["latitude", "Latitude"],
          ["longitude", "Longitude"],
          ["capturedAt", "Captured At"],
          ["informRequired", "Inform Required?", true],
          ["informed", "Concerned Authority Informed?", true],
          ["department", "Department"],
          ["privateAgency", "Private Agency / Organisation"],
          ["trafficPoliceStation", "Traffic Police Station"],
          ["name", "Name"],
          ["rank", "Rank / Designation"],
          ["cellNo", "Cell No."],
          ["remarks", "Remarks"],
          ["saved", "Issue Saved?", true],
        ].map(([key, fieldLabel, status]) => (
          <Field key={String(key)} label={String(fieldLabel)} value={issue[String(key)]} status={Boolean(status)} />
        ))}
      </div>
    </div>
  );
}

function RouteView({ result }: { result: JsonObject }) {
  const entering = obj(result.enteringPoint);
  const stretches = arr(result.routeStretches);

  return (
    <div className="space-y-5">
      <Section eyebrow="MODULE 4" title="Route-Based Verification">
        {fields(result, [
          ["idolConstructedAtLocation", "Idol Constructed at Location?", true],
          ["constructedAtLocationProcessionRouteVerified", "Constructed-at-Location Procession Route Verified?", true, no(result.constructedAtLocationProcessionRouteVerified)],
          ["installationRouteVerified", "Installation Route Verified?", true, no(result.installationRouteVerified)],
          ["remarks", "Route Verification Remarks"],
          ["recordScope", "Record Scope"],
          ["shareWithLinkedIdols", "Share With Linked Idols?", true],
        ])}
      </Section>

      <Section title="Entering Point">
        <div className="grid gap-3 md:grid-cols-2 lg:grid-cols-4">
          <Field label="Name / Description" value={entering?.name} />
          <Field label="Latitude" value={entering?.latitude} />
          <Field label="Longitude" value={entering?.longitude} />
          <Field label="Captured At" value={dateText(entering?.capturedAt)} />
        </div>
      </Section>

      <Section title={`Route Stretches (${stretches.length})`}>
        {stretches.length === 0 ? (
          <p className="text-sm text-slate-400">No route stretches recorded.</p>
        ) : (
          <div className="space-y-5">
            {stretches.map((stretchValue, stretchIndex) => {
              const stretch = obj(stretchValue);
              if (!stretch) return null;
              const issues = arr(stretch.issues);
              return (
                <div key={stretchIndex} className="rounded-xl border border-slate-300 bg-slate-50 p-4">
                  <h5 className="font-bold text-[#17365D]">
                    Stretch {text(stretch.stretchNo) || stretchIndex + 1}: {text(stretch.pointName) || "Route Point"}
                  </h5>
                  <div className="mt-3 grid gap-3 md:grid-cols-2 lg:grid-cols-4">
                    <Field label="Latitude" value={stretch.latitude} />
                    <Field label="Longitude" value={stretch.longitude} />
                    <Field label="Captured At" value={dateText(stretch.capturedAt)} />
                    <Field label="Reached Mandap?" value={stretch.reachedMandap} status warning={no(stretch.reachedMandap)} />
                  </div>
                  <div className="mt-4 space-y-3">
                    {issues.map((issueValue, issueIndex) => {
                      const issue = obj(issueValue);
                      return issue ? <RouteIssue key={issueIndex} issue={issue} index={issueIndex} /> : null;
                    })}
                  </div>
                </div>
              );
            })}
          </div>
        )}
        <div className="mt-3">
          <Field label="Verified At" value={dateText(result.verifiedAt)} />
        </div>
      </Section>

      <RawPayload name="Route Verification" result={result} />
    </div>
  );
}

/* MODULE 5 */

function SecurityView({ result }: { result: JsonObject }) {
  const points = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

  const pointTitles: Record<number, string> = {
    2: "Organiser / Volunteer Security Arrangements Available?",
    3: "CCTV Surveillance Available at the Mandap?",
    4: "Barricading / Access Control Arrangements Available at the Mandap?",
    5: "Fire Safety Arrangements Available at the Mandap?",
    6: "Electrical Safety Arrangements Proper at the Mandap?",
    7: "Emergency Vehicle Access Available up to the Mandap?",
    8: "Adequate Crowd Management Arrangements Available at the Mandap?",
    9: "Safe Entry and Exit Arrangements Available at the Mandap?",
    10: "Adequate Lighting Arrangements Available at and around the Mandap?",
    11: "Public Address (PA) / Announcement System Available at the Mandap?",
    12: "Emergency Contact Numbers (Given by SHO) Displayed at the Mandap?",
  };

  return (
    <div className="space-y-5">
      <Section eyebrow="MODULE 5" title="Security-Based Verification">
        <div className="grid gap-3 md:grid-cols-2">
          <Field
            label="Security Arrangements Verified?"
            value={result.securityVerified}
            status
            warning={no(result.securityVerified)}
          />
          <Field label="Security Verification Remarks" value={result.securityVerificationRemarks} />
        </div>
      </Section>

      {points.map((pointNo) => {
        const point = obj(result[`point${pointNo}`]);
        return (
          <Section key={pointNo} eyebrow={`POINT ${pointNo}`} title={pointTitles[pointNo]}>
            {point ? <RawValue value={point} /> : <p className="text-sm text-slate-400">No data stored for this point.</p>}
          </Section>
        );
      })}

      <RawPayload name="Security Verification" result={result} />
    </div>
  );
}

/* MODULE 6 */

function OrganizerView({ result }: { result: JsonObject }) {
  const organizers = arr(result.organizers);

  return (
    <div className="space-y-5">
      <Section eyebrow="MODULE 6" title="Organizer-Based Verification">
        {fields(result, [
          ["gpid", "GPID"],
          ["applicationId", "Application ID"],
          ["allOrganizersPersonallyVerified", "All Organizers Personally Verified?", true, no(result.allOrganizersPersonallyVerified)],
          ["remarks", "Verification Remarks"],
          ["mainOrganizerListed", "Main Organiser Listed?", true, no(result.mainOrganizerListed)],
          ["fieldOfficerDeclaration", "Field Officer Declaration", true],
        ])}
        <div className="mt-3">
          <Field label="Verified At" value={dateText(result.verifiedAt)} />
        </div>
      </Section>

      <Section title={`Organizer / Member Records (${organizers.length})`}>
        <div className="space-y-4">
          {organizers.length === 0 ? (
            <p className="text-sm text-slate-400">No organizer/member records stored.</p>
          ) : (
            organizers.map((personValue, index) => {
              const person = obj(personValue);
              if (!person) return null;
              const adverseCases = arr(person.adverseCases);

              return (
                <div key={index} className="rounded-xl border border-slate-200 bg-slate-50 p-4">
                  <h5 className="font-bold text-[#17365D]">
                    {index + 1}. {text(person.name) || "Organizer / Member"}
                  </h5>

                  <div className="mt-3 grid gap-3 md:grid-cols-2 lg:grid-cols-4">
                    {[
                      ["mobile", "Mobile"],
                      ["isApplicant", "Is Applicant?", true],
                      ["manuallyAdded", "Manually Added?", true],
                      ["role", "Role"],
                      ["otherRole", "Other Role"],
                      ["memberOfOtherAssociation", "Member of Other Association?", true],
                      ["otherAssociationGpid", "Other Association GPID"],
                      ["contactVerified", "Contact Verified?", true],
                      ["contactRemarks", "Contact Remarks"],
                    ].map(([key, fieldLabel, status]) => (
                      <Field
                        key={String(key)}
                        label={String(fieldLabel)}
                        value={person[String(key)]}
                        status={Boolean(status)}
                        warning={String(key) === "contactVerified" && no(person.contactVerified)}
                      />
                    ))}
                  </div>

                  <div className="mt-4 rounded-xl border border-red-300 bg-red-50 p-4">
                    <p className="text-xs font-bold tracking-widest text-red-700">
                      CONFIDENTIAL · OFFICIAL USE ONLY
                    </p>
                    <h6 className="mt-1 font-bold text-red-900">Adverse Information / Previous Cases</h6>
                    <div className="mt-3">
                      <Field
                        label="Adverse Information?"
                        value={person.adverseInformation}
                        status
                        warning={yes(person.adverseInformation)}
                      />
                    </div>
                    {yes(person.adverseInformation) && (
                      <div className="mt-3 space-y-3">
                        {adverseCases.map((caseValue, caseIndex) => {
                          const adverseCase = obj(caseValue);
                          if (!adverseCase) return null;
                          return (
                            <div key={caseIndex} className="rounded-lg border border-red-200 bg-white p-3">
                              <p className="mb-3 text-xs font-bold text-red-700">CASE {caseIndex + 1}</p>
                              <div className="grid gap-3 md:grid-cols-2">
                                <Field label="Nature" value={adverseCase.nature} warning />
                                <Field label="Police Station" value={adverseCase.policeStation} warning />
                                <Field label="Crime Reference" value={adverseCase.crimeReference} />
                                <Field label="Remarks" value={adverseCase.remarks} />
                              </div>
                            </div>
                          );
                        })}
                      </div>
                    )}
                  </div>
                </div>
              );
            })
          )}
        </div>
      </Section>

      <RawPayload name="Organizer Verification" result={result} confidential />
    </div>
  );
}

/* MODULE 7 */

function CoordinationItem({ item, index }: { item: JsonObject; index: number }) {
  const required = yes(item.coordinationRequired);
  const status = text(item.status);

  return (
    <div
      className={`rounded-xl border p-4 ${
        status === "Rejected"
          ? "border-red-300 bg-red-50"
          : required && status !== "NOC / Clearance Received" && status !== "Not Applicable"
            ? "border-amber-200 bg-amber-50"
            : "border-slate-200 bg-white"
      }`}
    >
      <p className="text-xs font-bold tracking-widest text-slate-400">REQUIREMENT {index + 1}</p>
      <h5 className="mt-1 font-bold text-[#17365D]">{text(item.sourceModule) || "Source Module"}</h5>
      <p className="mt-3 rounded-lg border border-slate-200 bg-white p-3 text-sm text-slate-700">
        {text(item.finding) || "-"}
      </p>

      <div className="mt-3 grid gap-3 md:grid-cols-2 lg:grid-cols-4">
        <Field label="Coordination / NOC Required?" value={item.coordinationRequired} status warning={required} />
        {!required && <Field label="Not Required Reason" value={item.notRequiredReason} />}
        {required && <Field label="Department / Agency" value={item.department} />}
        {required && <Field label="Status" value={item.status} warning={status !== "NOC / Clearance Received" && status !== "Not Applicable"} />}
        {required && <Field label="Reference / Application No." value={item.referenceNo} />}
        {required && <Field label="Reference Date" value={dateText(item.referenceDate)} />}
        {required && <Field label="Remarks" value={item.remarks} />}
        {status === "NOC / Clearance Received" && (
          <Field label="NOC / Clearance Document Reference" value={item.documentReference} />
        )}
        {status === "Conditional Clearance" && (
          <>
            <Field label="Conditions" value={item.conditions} warning />
            <Field label="Conditions Complied?" value={item.conditionsComplied} status warning={no(item.conditionsComplied)} />
          </>
        )}
        {status === "Rejected" && (
          <>
            <Field label="Rejection Reason" value={item.rejectionReason} warning />
            <Field label="Further Action / Remarks" value={item.furtherAction} warning />
          </>
        )}
      </div>
    </div>
  );
}

function InterDepartmentalView({ result }: { result: JsonObject }) {
  const items = arr(result.autoIdentifiedRequirements);
  const additional = obj(result.additionalCoordination);
  const unresolved = obj(result.unresolvedIssueDetails);
  const additionalRequired = yes(result.additionalCoordinationRequired);
  const unresolvedIssue = yes(result.unresolvedInterDepartmentalIssue);

  return (
    <div className="space-y-5">
      <Section eyebrow="MODULE 7" title="Inter-Departmental Coordination / NOCs">
        {fields(result, [
          ["gpid", "GPID"],
          ["applicationId", "Application ID"],
          ["additionalCoordinationRequired", "Additional Coordination Required?", true, additionalRequired],
          ["unresolvedInterDepartmentalIssue", "Unresolved Inter-Departmental Issue?", true, unresolvedIssue],
          ["fieldOfficerConfirmation", "Field Officer Confirmation", true],
        ])}
        <div className="mt-3">
          <Field label="Verified At" value={dateText(result.verifiedAt)} />
        </div>
      </Section>

      <Section title={`Auto-Identified Coordination Requirements (${items.length})`}>
        {items.length === 0 ? (
          <div className="rounded-lg border border-green-200 bg-green-50 p-4 text-sm text-green-800">
            No specific coordination requirement was automatically identified from the available verification findings.
          </div>
        ) : (
          <div className="space-y-4">
            {items.map((itemValue, index) => {
              const item = obj(itemValue);
              return item ? <CoordinationItem key={index} item={item} index={index} /> : null;
            })}
          </div>
        )}
      </Section>

      <Section title="Additional Coordination Required?" tone={additionalRequired ? "warning" : "normal"}>
        <Field label="Additional Coordination Required" value={result.additionalCoordinationRequired} status warning={additionalRequired} />
        {additionalRequired && (
          <div className="mt-3 grid gap-3 md:grid-cols-2 lg:grid-cols-3">
            <Field label="Department / Agency" value={additional?.department} warning />
            <Field label="Reason for Coordination" value={additional?.reason} warning />
            <Field label="Status" value={additional?.status} warning />
            <Field label="Reference / Application No." value={additional?.referenceNo} />
            <Field label="Remarks" value={additional?.remarks} />
          </div>
        )}
      </Section>

      <Section title="Any Unresolved Inter-Departmental Issue?" tone={unresolvedIssue ? "warning" : "normal"}>
        <Field
          label="Unresolved Inter-Departmental Issue"
          value={result.unresolvedInterDepartmentalIssue}
          status
          warning={unresolvedIssue}
        />
        {unresolvedIssue && (
          <div className="mt-3 grid gap-3 md:grid-cols-2">
            <Field label="Department / Agency" value={unresolved?.department} warning />
            <Field label="Issue / Pending Requirement" value={unresolved?.issue} warning />
            <Field label="Action Required" value={unresolved?.actionRequired} warning />
            <Field label="Remarks" value={unresolved?.remarks} />
          </div>
        )}
      </Section>

      <RawPayload name="Inter-Departmental Coordination / NOCs" result={result} />
    </div>
  );
}

/* MODULE 8 */

function shoAdverseFindings(record: VerificationRecord): string[] {
  const findings: string[] = [];
  const location = obj(record.locationResult);
  const mandap = obj(record.mandapResult);
  const idol = obj(record.idolResult);
  const route = obj(record.routeResult);
  const security = obj(record.securityResult);
  const organizer = obj(record.organizerResult);
  const coordination = obj(record.interDepartmentalResult);

  if (location) {
    if (no(location.locationVerified)) findings.push(`Location: Installation location was not verified. Remarks: ${text(location.remarks) || "-"}`);
    if (yes(location.locationChanged)) findings.push(`Location: Installation location has changed. Police Station: ${text(location.policeStation) || "-"}; Sector: ${text(location.sector) || "-"}.`);
    if (yes(location.disputedLand)) findings.push(`Location: Disputed land/location issue recorded. Remarks: ${text(location.disputedLandRemarks) || "-"}`);
    const sensitivity = text(location.sensitivity).toUpperCase();
    if (sensitivity === "MEDIUM" || sensitivity === "HIGH") {
      findings.push(`Location: ${sensitivity} sensitivity location. Remarks: ${text(location.sensitivityRemarks) || "-"}`);
    }
  }

  if (mandap) {
    if (no(mandap.mandapInstalled)) {
      findings.push(`Mandap: Mandap was not installed. Remarks: ${text(mandap.mandapNotInstalledRemarks) || "-"}`);
    } else {
      if (no(mandap.structuralStability)) findings.push(`Mandap: Structural stability not satisfactory. Remarks: ${text(mandap.structuralRemarks) || "-"}`);
      if (yes(mandap.roadObstruction)) findings.push(`Mandap: Road obstruction recorded. Type: ${text(mandap.obstructionType) || "-"}; Traffic impact: ${text(mandap.trafficImpact) || "-"}.`);
      if (no(mandap.emergencyAccess)) findings.push(`Mandap: Emergency access not satisfactory. Remarks: ${text(mandap.emergencyRemarks) || "-"}`);
      if (yes(mandap.overheadWires) || yes(mandap.overheadWiresRisk)) findings.push(`Mandap: Overhead wire issue/risk recorded. Remarks: ${text(mandap.overheadWiresRemarks) || "-"}`);
      if (yes(mandap.electricalHazard) || yes(mandap.electricalHazardRisk)) findings.push(`Mandap: Electrical hazard/risk recorded. Remarks: ${text(mandap.electricalHazardRemarks) || "-"}`);
      if (no(mandap.mandapHeightVerified)) findings.push(`Mandap: Height mismatch. Declared: ${text(mandap.declaredMandapHeight) || "-"}; Actual: ${text(mandap.actualMandapHeight) || "-"}.`);
    }
  }

  if (idol) {
    if (no(idol.idolInstalled)) findings.push("Idol: Idol was not installed at verification time.");
    if (no(idol.heightMatches)) findings.push(`Idol: Height mismatch. Declared: ${text(idol.declaredIdolHeight) || "-"}; Actual: ${text(idol.actualHeightFeet) || "-"} ft ${text(idol.actualHeightInches) || "-"} in.`);
    if (no(idol.basePlatformSafe)) findings.push(`Idol: Base/platform was not found safe. Remarks: ${text(idol.baseSafetyRemarks) || "-"}`);
  }

  if (route) {
    if (no(route.installationRouteVerified)) findings.push(`Route: Installation route was not verified. Remarks: ${text(route.remarks) || "-"}`);
    if (no(route.constructedAtLocationProcessionRouteVerified)) findings.push("Route: Procession route for Idol constructed at location was not verified.");
    for (const stretchValue of arr(route.routeStretches)) {
      const stretch = obj(stretchValue);
      if (!stretch) continue;
      for (const issueValue of arr(stretch.issues)) {
        const issue = obj(issueValue);
        if (!issue || !yes(issue.noticed)) continue;
        findings.push(`Route: ${text(issue.title) || "-"}. Department: ${text(issue.department) || "-"}; Informed: ${text(issue.informed) || "-"}; Remarks: ${text(issue.remarks) || "-"}`);
      }
    }
  }

  if (security) {
    if (no(security.securityVerified)) findings.push(`Security: Security verification was not satisfactory/completed. Remarks: ${text(security.securityVerificationRemarks) || "-"}`);
    for (const pointNo of [2, 4, 6, 7, 8, 9, 10, 11]) {
      const point = obj(security[`point${pointNo}`]);
      if (point && no(point.available)) {
        findings.push(`Security Point ${pointNo}: Required arrangement not available. Organiser informed: ${text(point.organiserInformed) || "-"}; Remarks: ${text(point.remarks) || "-"}`);
      }
    }
    const cctv = obj(security.point3);
    if (cctv && no(cctv.cctvAvailable)) findings.push(`Security: CCTV not available. Remarks: ${text(cctv.remarks) || "-"}`);
    const fire = obj(security.point5);
    if (
      fire &&
      (no(fire.fireExtinguisherAvailable) ||
        no(fire.waterArrangementAvailable) ||
        no(fire.sandArrangementAvailable))
    ) {
      findings.push(`Security: One or more fire safety arrangements are not available. Remarks: ${text(fire.remarks) || "-"}`);
    }
  }

  if (organizer) {
    if (no(organizer.allOrganizersPersonallyVerified)) findings.push(`Organizer: All organizers were not personally verified. Remarks: ${text(organizer.remarks) || "-"}`);
    for (const personValue of arr(organizer.organizers)) {
      const person = obj(personValue);
      if (!person) continue;
      if (no(person.contactVerified)) findings.push(`Organizer: Contact verification not completed for ${text(person.name) || "-"}.`);
      if (yes(person.adverseInformation)) findings.push(`Organizer: CONFIDENTIAL police-review finding exists for ${text(person.name) || "-"}.`);
    }
  }

  if (coordination) {
    for (const itemValue of arr(coordination.autoIdentifiedRequirements)) {
      const item = obj(itemValue);
      if (!item || !yes(item.coordinationRequired)) continue;
      const status = text(item.status) || "-";
      if (status !== "NOC / Clearance Received" && status !== "Not Applicable") {
        findings.push(`Inter-Departmental: ${text(item.finding) || "-"} Department: ${text(item.department) || "-"}; Status: ${status}.`);
      }
      if (status === "Conditional Clearance" && no(item.conditionsComplied)) {
        findings.push(`Inter-Departmental: Conditional clearance conditions are not yet complied with for ${text(item.department) || "-"}.`);
      }
      if (status === "Rejected") {
        findings.push(`Inter-Departmental: Coordination / clearance was rejected by ${text(item.department) || "-"}. Reason: ${text(item.rejectionReason) || "-"}.`);
      }
    }

    if (yes(coordination.additionalCoordinationRequired)) {
      const additional = obj(coordination.additionalCoordination);
      if (additional) {
        const status = text(additional.status) || "-";
        if (status !== "NOC / Clearance Received" && status !== "Not Applicable") {
          findings.push(`Inter-Departmental: Additional coordination with ${text(additional.department) || "-"} is ${status}. Reason: ${text(additional.reason) || "-"}.`);
        }
      }
    }

    if (yes(coordination.unresolvedInterDepartmentalIssue)) {
      const unresolved = obj(coordination.unresolvedIssueDetails);
      findings.push(`Inter-Departmental: Unresolved issue with ${text(unresolved?.department) || "-"}. Issue: ${text(unresolved?.issue) || "-"}; Action required: ${text(unresolved?.actionRequired) || "-"}.`);
    }
  }

  return findings;
}

function PermissionShoView({
  result,
  record,
}: {
  result: JsonObject;
  record: VerificationRecord;
}) {
  const summary = MODULES.slice(0, 7).map((module) => ({
    module,
    completed: record[module.key] != null,
  }));
  const adverse = shoAdverseFindings(record);
  const recommendation = text(result.permissionRecommendation);

  return (
    <div className="space-y-5">
      <Section eyebrow="MODULE 8" title="Permission / SHO Review">
        {fields(result, [
          ["gpid", "GPID"],
          ["applicationId", "Application ID"],
          ["allRequiredVerificationsCompleted", "All Required Verifications Completed?", true, no(result.allRequiredVerificationsCompleted)],
          ["allObservationsAddressed", "All Observations / Deficiencies Addressed?", true, no(result.allObservationsAddressed)],
          ["departmentalCoordinationCompleted", "Required Departmental Coordination / NOCs Completed?", true, no(result.departmentalCoordinationCompleted)],
          ["permissionRecommendation", "SHO Recommendation", false, recommendation === "Not Recommended"],
          ["conditions", "Conditions / Instructions"],
          ["notRecommendedReason", "Reason for Not Recommending"],
          ["shoRemarks", "Final SHO Remarks / Instructions"],
          ["shoConfirmation", "SHO Confirmation", true],
        ])}
        <div className="mt-3">
          <Field label="Reviewed At" value={dateText(result.reviewedAt)} />
        </div>
      </Section>

      <Section eyebrow="SECTION A" title="Verification Summary">
        <div className="space-y-2">
          {summary.map(({ module, completed }) => (
            <div key={module.key} className="flex flex-wrap items-center justify-between gap-3 rounded-lg border border-slate-200 bg-white px-4 py-3">
              <p className="font-semibold text-slate-800">
                {module.number}. {module.title}
              </p>
              <span
                className={`rounded-full px-3 py-1 text-xs font-bold ${
                  completed ? "bg-green-50 text-green-700" : "bg-amber-50 text-amber-700"
                }`}
              >
                {completed ? "COMPLETED" : "NOT COMPLETED"}
              </span>
            </div>
          ))}
        </div>
      </Section>

      <Section eyebrow="SECTION B" title={`Pending / Adverse Issues (${adverse.length})`}>
        {adverse.length === 0 ? (
          <div className="rounded-lg border border-green-200 bg-green-50 p-4 text-sm text-green-800">
            No pending / adverse issue was automatically identified from the available verification results.
          </div>
        ) : (
          <div className="space-y-3">
            {adverse.map((finding, index) => {
              const confidential = finding.includes("CONFIDENTIAL");
              return (
                <div
                  key={`${index}-${finding}`}
                  className={`rounded-lg border p-4 ${
                    confidential ? "border-red-300 bg-red-50" : "border-amber-200 bg-amber-50"
                  }`}
                >
                  {confidential && (
                    <p className="mb-1 text-xs font-bold tracking-widest text-red-700">
                      CONFIDENTIAL · OFFICIAL USE ONLY
                    </p>
                  )}
                  <p className={confidential ? "text-sm font-medium text-red-900" : "text-sm font-medium text-amber-900"}>
                    {index + 1}. {finding}
                  </p>
                </div>
              );
            })}
          </div>
        )}
      </Section>

      <Section eyebrow="SECTION C" title="SHO Field Review">
        <div className="grid gap-3 md:grid-cols-2 lg:grid-cols-3">
          <Field label="All Required Verifications Completed?" value={result.allRequiredVerificationsCompleted} status warning={no(result.allRequiredVerificationsCompleted)} />
          <Field label="All Observations / Deficiencies Satisfactorily Addressed?" value={result.allObservationsAddressed} status warning={no(result.allObservationsAddressed)} />
          <Field label="Required Departmental Coordination / NOCs Completed?" value={result.departmentalCoordinationCompleted} status warning={no(result.departmentalCoordinationCompleted)} />
        </div>
      </Section>

      <Section eyebrow="SECTION D" title="Permission Decision" tone={recommendation === "Not Recommended" ? "warning" : "normal"}>
        <div className="grid gap-3 md:grid-cols-2">
          <Field label="SHO Recommendation" value={result.permissionRecommendation} warning={recommendation === "Not Recommended"} />
          {recommendation === "Recommended with Conditions" && (
            <Field label="Mandatory Conditions / Instructions" value={result.conditions} warning />
          )}
          {recommendation === "Not Recommended" && (
            <Field label="Mandatory Reason for Not Recommending" value={result.notRecommendedReason} warning />
          )}
        </div>
      </Section>

      <Section eyebrow="SECTION E" title="SHO Remarks">
        <Field label="Final Remarks / Instructions" value={result.shoRemarks} />
      </Section>

      <Section eyebrow="SECTION F" title="SHO Confirmation">
        <Field label="SHO Confirmation" value={result.shoConfirmation} status warning={!yes(result.shoConfirmation)} />
      </Section>

      <RawPayload name="Permission / SHO Review" result={result} confidential />
    </div>
  );
}

/* MAIN PAGE */

function InfoCard({ label: cardLabel, value }: { label: string; value: string }) {
  return (
    <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
      <p className="text-sm text-slate-500">{cardLabel}</p>
      <p className="mt-2 break-words text-xl font-bold text-[#17365D]">{value}</p>
    </div>
  );
}

export default function GpidVerificationDetailsPage() {
  const params = useParams<{ gpid: string }>();
  const router = useRouter();
  const gpid = decodeURIComponent(params?.gpid ?? "");

  const [record, setRecord] = useState<VerificationRecord | null>(null);
  const [application, setApplication] = useState<GaneshApplicationRecord | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [expandedModule, setExpandedModule] = useState<ModuleKey | null>(null);

  useEffect(() => {
    let active = true;

    async function loadDetails() {
      try {
        const [verificationResponse, gpidResponse] = await Promise.all([
          fetch("/api/verification", {
            method: "GET",
            cache: "no-store",
          }),
          fetch("/api/gpid", {
            method: "GET",
            cache: "no-store",
          }),
        ]);

        if (!verificationResponse.ok) {
          throw new Error(
            `Unable to load verification data. Status ${verificationResponse.status}`
          );
        }

        if (!gpidResponse.ok) {
          throw new Error(
            `Unable to load GPID master data. Status ${gpidResponse.status}`
          );
        }

        const verificationData: unknown = await verificationResponse.json();
        const gpidData: unknown = await gpidResponse.json();

        if (!Array.isArray(verificationData)) {
          throw new Error("Unexpected verification API response.");
        }

        if (!Array.isArray(gpidData)) {
          throw new Error("Unexpected GPID API response.");
        }

        const cleanGpid = gpid.trim().toLowerCase();

        const matchedVerification = (verificationData as VerificationRecord[]).find(
          (item) =>
            String(item.gpid ?? "")
              .trim()
              .toLowerCase() === cleanGpid
        );

        const matchedApplication = (gpidData as GaneshApplicationRecord[]).find(
          (item) =>
            String(item.unique_id ?? "")
              .trim()
              .toLowerCase() === cleanGpid
        );

        if (!active) {
          return;
        }

        setRecord(matchedVerification ?? null);
        setApplication(matchedApplication ?? null);

        if (!matchedVerification && !matchedApplication) {
          setError(`No GPID/application record was found for ${gpid}.`);
          setExpandedModule(null);
          return;
        }

        setError("");

        if (matchedVerification) {
          const firstCompleted = MODULES.find(
            (module) => matchedVerification[module.key] != null
          );
          setExpandedModule(firstCompleted?.key ?? null);
        } else {
          setExpandedModule(null);
        }
      } catch (err) {
        console.error(err);

        if (!active) {
          return;
        }

        setError("Unable to load the GPID supervisory details.");
        setRecord(null);
        setApplication(null);
      } finally {
        if (active) {
          setLoading(false);
        }
      }
    }

    const timer = window.setTimeout(() => {
      void loadDetails();
    }, 0);

    return () => {
      active = false;
      window.clearTimeout(timer);
    };
  }, [gpid]);

  if (loading) {
    return (
      <main className="flex min-h-screen items-center justify-center bg-slate-100">
        <div className="rounded-xl border border-slate-200 bg-white px-8 py-6 text-slate-600 shadow-sm">
          Loading GPID details...
        </div>
      </main>
    );
  }

  if (!record && !application) {
    return (
      <main className="min-h-screen bg-slate-100">
        <header className="bg-[#17365D] text-white">
          <div className="mx-auto max-w-[1500px] px-6 py-5">
            <h1 className="text-2xl font-bold">GPID Verification Details</h1>
          </div>
        </header>

        <div className="mx-auto max-w-[1500px] px-6 py-8">
          <div className="rounded-xl border border-red-200 bg-white p-6">
            <p className="font-semibold text-red-700">
              {error || "GPID/application record not found."}
            </p>

            <div className="mt-5 flex flex-wrap gap-3">
              <button
                onClick={() => router.push("/dashboard")}
                className="rounded-lg bg-[#17365D] px-5 py-2.5 text-white"
              >
                ← Back to Dashboard
              </button>

              <button
                onClick={() => router.push("/pre-installation")}
                className="rounded-lg border border-slate-300 bg-white px-5 py-2.5 text-slate-700"
              >
                Pre-Installation
              </button>
            </div>
          </div>
        </div>
      </main>
    );
  }

  const completedModules = record
    ? MODULES.filter((module) => record[module.key] != null).length
    : 0;

  const displayGpid =
    record?.gpid ||
    String(application?.unique_id ?? "").trim() ||
    gpid;

  const applicationStatus = text(application?.status).toUpperCase();

  const applicationStatusClass =
    applicationStatus === "APPROVED"
      ? "border-green-200 bg-green-50 text-green-700"
      : applicationStatus === "REJECTED"
        ? "border-red-200 bg-red-50 text-red-700"
        : applicationStatus === "PENDING"
          ? "border-amber-200 bg-amber-50 text-amber-700"
          : "border-slate-200 bg-slate-50 text-slate-700";

  return (
    <main className="min-h-screen bg-slate-100">
      <header className="bg-[#17365D] text-white">
        <div className="mx-auto flex max-w-[1500px] flex-wrap items-center justify-between gap-4 px-6 py-5">
          <div>
            <p className="text-xs tracking-widest text-blue-200">
              PRE-INSTALLATION · SUPERVISORY VIEW
            </p>
            <h1 className="mt-1 text-2xl font-bold">
              GPID Verification Details
            </h1>
            <p className="mt-1 text-blue-100">{displayGpid}</p>
          </div>

          <div className="flex flex-wrap gap-3">
            <button
              onClick={() => router.push("/dashboard")}
              className="rounded-lg border border-white/30 px-4 py-2 hover:bg-white/10"
            >
              ← Dashboard
            </button>

            <button
              onClick={() => router.push("/pre-installation")}
              className="rounded-lg border border-white/30 px-4 py-2 hover:bg-white/10"
            >
              Pre-Installation
            </button>
          </div>
        </div>
      </header>

      <div className="mx-auto max-w-[1500px] px-6 py-7">
        {error && (
          <div className="mb-5 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-red-700">
            {error}
          </div>
        )}

        {!record && application && (
          <section className="mb-6 rounded-xl border border-amber-300 bg-amber-50 p-5">
            <div className="flex flex-wrap items-start justify-between gap-4">
              <div>
                <p className="text-xs font-bold tracking-widest text-amber-700">
                  VERIFICATION STATUS
                </p>
                <h2 className="mt-1 text-xl font-bold text-amber-900">
                  Pre-Installation Verification Not Yet Started
                </h2>
                <p className="mt-2 text-sm text-amber-800">
                  This GPID exists in the live Ganesh application data, but no
                  Pre-Installation verification record has yet been created in
                  the verification system.
                </p>
              </div>

              <span className="rounded-full border border-amber-300 bg-white px-4 py-2 text-xs font-bold text-amber-800">
                0 / 8 MODULES
              </span>
            </div>
          </section>
        )}

        <section className="mb-7 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <InfoCard label="GPID" value={displayGpid} />
          <InfoCard
            label="Reference / Application ID"
            value={
              record?.applicationId ||
              text(application?.ref_no) ||
              "-"
            }
          />
          <InfoCard
            label="Modules Completed"
            value={`${completedModules} / 8`}
          />
          <InfoCard
            label="Verification Status"
            value={
              record?.verificationStatus ||
              (application ? "NOT STARTED" : "UNKNOWN")
            }
          />
        </section>

        {application && (
          <section className="mb-7 rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
            <div className="mb-5 flex flex-wrap items-center justify-between gap-3">
              <div>
                <p className="text-xs font-bold tracking-widest text-slate-400">
                  LIVE GANESH APPLICATION
                </p>
                <h2 className="mt-1 text-xl font-bold text-[#17365D]">
                  Application / GPID Information
                </h2>
              </div>

              <span
                className={`inline-flex rounded-full border px-4 py-2 text-xs font-bold ${applicationStatusClass}`}
              >
                {text(application?.status) || "STATUS NOT AVAILABLE"}
              </span>
            </div>

            <div className="grid gap-3 md:grid-cols-2 lg:grid-cols-4">
              <Field label="GPID" value={application.unique_id} />
              <Field label="Reference ID" value={application.ref_no} />
              <Field label="Applicant Name" value={application.name} />
              <Field label="Mobile Number" value={application.mobile_no} />

              <Field label="Association / Mandal" value={application.association} />
              <Field label="Police Station" value={application.ps_name} />
              <Field label="Division" value={application.division_name} />
              <Field label="Zone" value={application.zone_name} />

              <Field label="District / Commissionerate" value={application.dist_name} />
              <Field label="Idol Type" value={application.idol_type} />
              <Field
                label="Declared Idol Height"
                value={
                  text(application.idol_height)
                    ? `${text(application.idol_height)} ft`
                    : ""
                }
              />
              <Field label="Area Category" value={application.idol_area_type} />

              <Field label="Installation From Date" value={application.instal_from_date} />
              <Field label="Installation To Date" value={application.instal_to_date} />
              <Field label="Immersion Date" value={application.immr_date} />
              <Field label="Immersion Point" value={application.riv_name} />

              <Field label="House / Location" value={application.h_no} />
              <Field label="Street" value={application.street} />
              <Field label="Town / City" value={application.town} />
              <Field label="PIN Code" value={application.pin} />
            </div>

            {text(application.address) && (
              <div className="mt-3">
                <Field label="Applicant Address" value={application.address} />
              </div>
            )}
          </section>
        )}

        {record && (
          <section className="mb-7 rounded-xl border border-slate-200 bg-white p-5">
            <div className="flex flex-wrap gap-6">
              <div>
                <p className="text-xs text-slate-500">Submitted At</p>
                <p className="mt-1 font-semibold text-slate-800">
                  {dateText(record.submittedAt)}
                </p>
              </div>

              <div>
                <p className="text-xs text-slate-500">Last Updated</p>
                <p className="mt-1 font-semibold text-slate-800">
                  {dateText(record.updatedAt)}
                </p>
              </div>
            </div>
          </section>
        )}

        <section className="mb-5">
          <h2 className="text-xl font-bold text-slate-800">
            Verification Modules
          </h2>
          <p className="mt-1 text-sm text-slate-500">
            {record
              ? "Select a completed module to view the complete Mobile verification information for supervisory review."
              : "No verification modules have been started for this GPID. All modules are shown below as pending."}
          </p>
        </section>

        <div className="space-y-4">
          {MODULES.map((module) => {
            const result = record?.[module.key] ?? null;
            const completed = result != null;
            const expanded = expandedModule === module.key;
            const resultObject = obj(result);

            return (
              <section
                key={module.key}
                className="overflow-hidden rounded-xl border border-slate-200 bg-white"
              >
                <button
                  type="button"
                  disabled={!completed}
                  onClick={() => {
                    if (completed) {
                      setExpandedModule(expanded ? null : module.key);
                    }
                  }}
                  className={`flex w-full items-center gap-4 px-5 py-5 text-left ${
                    completed
                      ? "cursor-pointer hover:bg-slate-50"
                      : "cursor-not-allowed bg-slate-50"
                  }`}
                >
                  <div
                    className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-full font-bold ${
                      completed
                        ? "bg-[#17365D] text-white"
                        : "bg-slate-200 text-slate-500"
                    }`}
                  >
                    {module.number}
                  </div>

                  <div className="min-w-0 flex-1">
                    <h3 className="font-bold text-slate-800">
                      {module.title}
                    </h3>
                    <p className="mt-1 text-sm text-slate-500">
                      {module.description}
                    </p>
                  </div>

                  <div className="flex items-center gap-3">
                    <span
                      className={`rounded-full px-3 py-1 text-xs font-semibold ${
                        completed
                          ? "bg-green-50 text-green-700"
                          : "bg-amber-50 text-amber-700"
                      }`}
                    >
                      {completed ? "COMPLETED" : "PENDING"}
                    </span>

                    {completed && (
                      <span className="text-xl text-slate-500">
                        {expanded ? "▲" : "▼"}
                      </span>
                    )}
                  </div>
                </button>

                {completed && expanded && resultObject && record && (
                  <div className="border-t border-slate-200 bg-slate-50 p-5">
                    {module.key === "locationResult" ? (
                      <LocationView
                        result={resultObject}
                        parentGpid={record.gpid}
                        parentApplicationId={record.applicationId}
                      />
                    ) : module.key === "mandapResult" ? (
                      <MandapView
                        result={resultObject}
                        parentGpid={record.gpid}
                        parentApplicationId={record.applicationId}
                      />
                    ) : module.key === "idolResult" ? (
                      <IdolView result={resultObject} />
                    ) : module.key === "routeResult" ? (
                      <RouteView result={resultObject} />
                    ) : module.key === "securityResult" ? (
                      <SecurityView result={resultObject} />
                    ) : module.key === "organizerResult" ? (
                      <OrganizerView result={resultObject} />
                    ) : module.key === "interDepartmentalResult" ? (
                      <InterDepartmentalView result={resultObject} />
                    ) : (
                      <PermissionShoView
                        result={resultObject}
                        record={record}
                      />
                    )}
                  </div>
                )}
              </section>
            );
          })}
        </div>

        <section className="mt-7 rounded-xl border border-blue-200 bg-blue-50 p-5">
          <h3 className="font-bold text-[#17365D]">Supervisory View</h3>
          <p className="mt-2 text-sm text-slate-700">
            The live Ganesh application identifies the GPID and its application
            particulars. Mobile captures Pre-Installation field verification
            data, and Web displays the same verification data for monitoring
            and supervisory review. A GPID without a verification record
            remains visible here and is clearly shown as not yet started.
          </p>
        </section>
      </div>
    </main>
  );
}

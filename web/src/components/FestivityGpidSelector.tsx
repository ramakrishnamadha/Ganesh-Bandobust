"use client";

import { useEffect, useMemo, useState } from "react";

export type GpidRecord = {
  gpid: string;
  name: string | null;
  address: string | null;
  association: string | null;
  mobile: string | null;
  range: string | null;
  zone: string | null;
  division: string | null;
  policeStation: string | null;
  installFromDate: string | null;
  installToDate: string | null;
  idolHeight: string | null;
  pandalHeight: string | null;
  idolType: string | null;
  immersionDate: string | null;
  immersionPlace: string | null;
  areaType: string | null;
  status: string | null;
  latitude: number | null;
  longitude: number | null;
};

type ApiResponse = {
  success: boolean;
  fetchedAt?: string;
  rangeAvailable?: boolean;
  records?: GpidRecord[];
  message?: string;
};

type Props = {
  onSelect: (record: GpidRecord | null) => void;
};

function unique(values: Array<string | null>) {
  return Array.from(
    new Set(
      values.filter(
        (value): value is string =>
          Boolean(value && value.trim()),
      ),
    ),
  ).sort((a, b) => a.localeCompare(b));
}

export default function FestivityGpidSelector({
  onSelect,
}: Props) {
  const [records, setRecords] = useState<GpidRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [rangeAvailable, setRangeAvailable] =
    useState(false);

  const [range, setRange] = useState("");
  const [zone, setZone] = useState("");
  const [division, setDivision] = useState("");
  const [policeStation, setPoliceStation] =
    useState("");
  const [gpid, setGpid] = useState("");

  async function loadData() {
    setLoading(true);
    setError(null);

    try {
      const response = await fetch(
        "/api/festivity/gpid-master",
        {
          method: "GET",
          cache: "no-store",
        },
      );

      const result =
        (await response.json()) as ApiResponse;

      if (!response.ok || !result.success) {
        throw new Error(
          result.message || "Unable to load GPID data.",
        );
      }

      setRecords(result.records ?? []);
      setRangeAvailable(
        Boolean(result.rangeAvailable),
      );

      setRange("");
      setZone("");
      setDivision("");
      setPoliceStation("");
      setGpid("");
      onSelect(null);
    } catch (err) {
      setError(
        err instanceof Error
          ? err.message
          : "Unable to load GPID data.",
      );

      setRecords([]);
      onSelect(null);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void loadData();
  }, []);

  const ranges = useMemo(
    () =>
      unique(records.map((record) => record.range)),
    [records],
  );

  const recordsAfterRange = useMemo(() => {
    if (!rangeAvailable) {
      return records;
    }

    if (!range) {
      return [];
    }

    return records.filter(
      (record) => record.range === range,
    );
  }, [records, rangeAvailable, range]);

  const zones = useMemo(
    () =>
      unique(
        recordsAfterRange.map(
          (record) => record.zone,
        ),
      ),
    [recordsAfterRange],
  );

  const recordsAfterZone = useMemo(() => {
    if (!zone) {
      return [];
    }

    return recordsAfterRange.filter(
      (record) => record.zone === zone,
    );
  }, [recordsAfterRange, zone]);

  const divisions = useMemo(
    () =>
      unique(
        recordsAfterZone.map(
          (record) => record.division,
        ),
      ),
    [recordsAfterZone],
  );

  const recordsAfterDivision = useMemo(() => {
    if (!division) {
      return [];
    }

    return recordsAfterZone.filter(
      (record) =>
        record.division === division,
    );
  }, [recordsAfterZone, division]);

  const policeStations = useMemo(
    () =>
      unique(
        recordsAfterDivision.map(
          (record) => record.policeStation,
        ),
      ),
    [recordsAfterDivision],
  );

  const gpidRecords = useMemo(() => {
    if (!policeStation) {
      return [];
    }

    return recordsAfterDivision
      .filter(
        (record) =>
          record.policeStation === policeStation,
      )
      .sort((a, b) =>
        a.gpid.localeCompare(b.gpid),
      );
  }, [recordsAfterDivision, policeStation]);

  function clearBelowRange() {
    setZone("");
    setDivision("");
    setPoliceStation("");
    setGpid("");
    onSelect(null);
  }

  function clearBelowZone() {
    setDivision("");
    setPoliceStation("");
    setGpid("");
    onSelect(null);
  }

  function clearBelowDivision() {
    setPoliceStation("");
    setGpid("");
    onSelect(null);
  }

  if (loading) {
    return (
      <div className="rounded-xl border border-blue-200 bg-blue-50 p-5">
        <p className="font-bold text-blue-900">
          Loading live GPID master...
        </p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="rounded-xl border border-red-200 bg-red-50 p-5">
        <p className="font-bold text-red-900">
          Unable to load GPID data
        </p>

        <p className="mt-2 text-sm text-red-700">
          {error}
        </p>

        <button
          type="button"
          onClick={() => void loadData()}
          className="mt-4 rounded-lg bg-red-700 px-4 py-2 text-sm font-semibold text-white"
        >
          Retry
        </button>
      </div>
    );
  }

  return (
    <div>
      <div className="mb-5 flex flex-wrap items-center justify-between gap-3 rounded-lg border border-blue-200 bg-blue-50 p-4">
        <div>
          <p className="font-bold text-blue-900">
            Live GPID Master
          </p>

          <p className="mt-1 text-sm text-blue-700">
            {records.length} GPID records loaded
          </p>
        </div>

        <button
          type="button"
          onClick={() => void loadData()}
          className="rounded-lg border border-blue-300 bg-white px-4 py-2 text-sm font-semibold text-blue-800"
        >
          Refresh
        </button>
      </div>

      {!rangeAvailable && (
        <div className="mb-5 rounded-lg border border-amber-200 bg-amber-50 p-4">
          <p className="font-semibold text-amber-900">
            Range data is not available in the current API response.
          </p>

          <p className="mt-1 text-sm text-amber-800">
            Range will not be guessed. You can continue from Zone for now.
            Range will be enabled after authoritative hierarchy data is connected.
          </p>
        </div>
      )}

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <Selector
          label="Range"
          value={range}
          disabled={!rangeAvailable}
          placeholder={
            rangeAvailable
              ? "Select Range"
              : "Range unavailable"
          }
          options={ranges}
          onChange={(value) => {
            setRange(value);
            clearBelowRange();
          }}
        />

        <Selector
          label="Zone"
          value={zone}
          disabled={
            rangeAvailable
              ? !range
              : records.length === 0
          }
          placeholder="Select Zone"
          options={zones}
          onChange={(value) => {
            setZone(value);
            clearBelowZone();
          }}
        />

        <Selector
          label="Division"
          value={division}
          disabled={!zone}
          placeholder="Select Division"
          options={divisions}
          onChange={(value) => {
            setDivision(value);
            clearBelowDivision();
          }}
        />

        <Selector
          label="Police Station"
          value={policeStation}
          disabled={!division}
          placeholder="Select Police Station"
          options={policeStations}
          onChange={(value) => {
            setPoliceStation(value);
            setGpid("");
            onSelect(null);
          }}
        />
      </div>

      <div className="mt-4">
        <label className="mb-2 block text-sm font-semibold text-slate-700">
          GPID
        </label>

        <select
          value={gpid}
          disabled={!policeStation}
          onChange={(event) => {
            const value = event.target.value;
            setGpid(value);

            const selected =
              gpidRecords.find(
                (record) =>
                  record.gpid === value,
              ) ?? null;

            onSelect(selected);
          }}
          className="w-full rounded-lg border border-slate-300 bg-white px-3 py-3 text-sm disabled:bg-slate-100"
        >
          <option value="">
            Select GPID
          </option>

          {gpidRecords.map((record) => (
            <option
              key={record.gpid}
              value={record.gpid}
            >
              {record.gpid}
              {record.association
                ? ` — ${record.association}`
                : ""}
            </option>
          ))}
        </select>

        {policeStation && (
          <p className="mt-2 text-sm font-semibold text-slate-600">
            {gpidRecords.length} GPID(s) available under{" "}
            {policeStation}
          </p>
        )}
      </div>
    </div>
  );
}

function Selector({
  label,
  value,
  disabled,
  placeholder,
  options,
  onChange,
}: {
  label: string;
  value: string;
  disabled: boolean;
  placeholder: string;
  options: string[];
  onChange: (value: string) => void;
}) {
  return (
    <div>
      <label className="mb-2 block text-sm font-semibold text-slate-700">
        {label}
      </label>

      <select
        value={value}
        disabled={disabled}
        onChange={(event) =>
          onChange(event.target.value)
        }
        className="w-full rounded-lg border border-slate-300 bg-white px-3 py-3 text-sm disabled:bg-slate-100"
      >
        <option value="">
          {placeholder}
        </option>

        {options.map((option) => (
          <option
            key={option}
            value={option}
          >
            {option}
          </option>
        ))}
      </select>
    </div>
  );
}

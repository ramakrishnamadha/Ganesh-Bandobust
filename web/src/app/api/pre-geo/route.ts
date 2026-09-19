const CURRENT_GPID_API =
  "https://policeportal.tspolice.gov.in/ganesh/getGanaDetails/22";

function normaliseText(value: unknown): string {
  if (value === null || value === undefined) {
    return "";
  }

  return String(value)
    .trim()
    .toUpperCase()
    .replace(/\s+/g, " ");
}

function normaliseName(value: unknown): string {
  return normaliseText(value)
    .replace(/[^A-Z0-9]/g, "");
}

function normalisePoliceStation(input: unknown): string {
  let value = normaliseText(input);

  value = value
    .replace(/\bPOLICE STATION\b/g, "")
    .replace(/\bP\.?\s*S\.?\s*$/g, "")
    .replace(/\s+/g, "")
    .replace(/[^A-Z0-9]/g, "");

  const confirmedAliases: Record<string, string> = {
    CHIKKADAPALLY: "CHIKKADPALLY",
    KHAIRATHABAD: "KHAIRATABAD",
    KALAPATHER: "KALAPATHAR",
    MEHDIPATNAM: "MEDIPATNAM",
    SHALIBANDA: "SHAHALIBANDA",
  };

  return confirmedAliases[value] ?? value;
}

function levenshteinDistance(a: string, b: string): number {
  const matrix: number[][] = [];

  for (let i = 0; i <= b.length; i++) {
    matrix[i] = [i];
  }

  for (let j = 0; j <= a.length; j++) {
    matrix[0][j] = j;
  }

  for (let i = 1; i <= b.length; i++) {
    for (let j = 1; j <= a.length; j++) {
      if (b.charAt(i - 1) === a.charAt(j - 1)) {
        matrix[i][j] = matrix[i - 1][j - 1];
      } else {
        matrix[i][j] = Math.min(
          matrix[i - 1][j - 1] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j] + 1
        );
      }
    }
  }

  return matrix[b.length][a.length];
}

function policeStationSimilarity(
  a: string,
  b: string
): {
  editDistance: number;
  similarityRatio: number;
  likelySamePoliceStation: boolean;
} {
  if (!a || !b) {
    return {
      editDistance: Math.max(a.length, b.length),
      similarityRatio: 0,
      likelySamePoliceStation: false,
    };
  }

  const editDistance =
    levenshteinDistance(a, b);

  const maxLength =
    Math.max(a.length, b.length);

  const similarityRatio =
    maxLength === 0
      ? 1
      : 1 - editDistance / maxLength;

  /*
   * Conservative rule:
   * - exact matches are already handled elsewhere
   * - for spelling variants, require both PS names to be reasonably long
   * - accept only very small edit differences
   */
  const minLength =
    Math.min(a.length, b.length);

  const likelySamePoliceStation =
    minLength >= 6 &&
    editDistance <= 2 &&
    similarityRatio >= 0.8;

  return {
    editDistance,
    similarityRatio:
      Number(similarityRatio.toFixed(3)),
    likelySamePoliceStation,
  };
}

function normaliseMobile(value: unknown): string {
  if (value === null || value === undefined) {
    return "";
  }

  let mobile = String(value)
    .replace(/\D/g, "")
    .trim();

  if (mobile.length > 10) {
    mobile = mobile.slice(-10);
  }

  return mobile;
}

export async function GET() {
  try {
    const preGeoApiUrl =
      process.env.GANESH_PRE_GEO_API_URL;

    const preGeoAuth =
      process.env.GANESH_PRE_GEO_AUTH;

    const preGeoApiKey =
      process.env.GANESH_PRE_GEO_API_KEY;

    if (
      !preGeoApiUrl ||
      !preGeoAuth ||
      !preGeoApiKey
    ) {
      return Response.json(
        {
          error:
            "Pre-Geo API configuration is missing",
        },
        {
          status: 500,
        }
      );
    }

    const preGeoResponse = await fetch(
      preGeoApiUrl,
      {
        method: "POST",
        headers: {
          "Content-Type":
            "application/json",
          Authorization:
            `Basic ${preGeoAuth}`,
        },
        body: JSON.stringify({
          request: {
            Apikey:
              preGeoApiKey,
          },
        }),
        cache: "no-store",
      }
    );

    if (!preGeoResponse.ok) {
      const responseText =
        await preGeoResponse.text();

      return Response.json(
        {
          error:
            "Failed to load 2025 Pre-Geo data",
          status:
            preGeoResponse.status,
          response:
            responseText,
        },
        {
          status:
            preGeoResponse.status,
        }
      );
    }

    const preGeoData =
      await preGeoResponse.json();

    const preGeoRecords =
      preGeoData
        ?.Ganesh2025listResult
        ?.Ganeshlist;

    if (!Array.isArray(preGeoRecords)) {
      return Response.json(
        {
          error:
            "Unexpected 2025 Pre-Geo API response structure",
        },
        {
          status: 500,
        }
      );
    }

    const currentResponse = await fetch(
      CURRENT_GPID_API,
      {
        method: "POST",
        cache: "no-store",
      }
    );

    if (!currentResponse.ok) {
      const responseText =
        await currentResponse.text();

      return Response.json(
        {
          error:
            "Failed to load current 2026 GPID data",
          status:
            currentResponse.status,
          response:
            responseText,
        },
        {
          status:
            currentResponse.status,
        }
      );
    }

    const currentRecords =
      await currentResponse.json();

    if (!Array.isArray(currentRecords)) {
      return Response.json(
        {
          error:
            "Unexpected current GPID API response structure",
        },
        {
          status: 500,
        }
      );
    }

    const preGeoByMobile =
      new Map<
        string,
        Record<string, unknown>[]
      >();

    for (const record of preGeoRecords) {
      const mobile =
        normaliseMobile(
          record.Mobile_No
        );

      if (!mobile) {
        continue;
      }

      const existing =
        preGeoByMobile.get(mobile) ?? [];

      existing.push(record);

      preGeoByMobile.set(
        mobile,
        existing
      );
    }

    let exactMobileMatched = 0;
    let uniqueMobileMatches = 0;
    let duplicateMobileMatches = 0;
    let duplicateMobileResolvedUnique = 0;
    let duplicateMobileAmbiguous = 0;
    let duplicateMobileUnresolved = 0;
    let mobileNotMatched = 0;
    let uniqueMobileNamePsMatch = 0;
    let uniqueMobileNameOnlyMatch = 0;
    let uniqueMobilePsOnlyMatch = 0;
    let uniqueMobileNeitherMatch = 0;

    let nameOnlyLikelySamePs = 0;
    let nameOnlyDifferentPs = 0;

    const likelySamePsPairCounts =
      new Map<
        string,
        {
          currentPoliceStation: string;
          preGeoPoliceStation: string;
          normalisedCurrentPoliceStation: string;
          normalisedPreGeoPoliceStation: string;
          editDistance: number;
          similarityRatio: number;
          count: number;
        }
      >();

    const strongMatches:
      Record<string, unknown>[] = [];

    const nameOnlyMatches:
      Record<string, unknown>[] = [];

    const likelySamePsSamples:
      Record<string, unknown>[] = [];

    const differentPsSamples:
      Record<string, unknown>[] = [];

    const psOnlyMatches:
      Record<string, unknown>[] = [];

    const neitherMatches:
      Record<string, unknown>[] = [];

    const duplicateMobileSamples:
      Record<string, unknown>[] = [];

    const duplicateResolvedSamples:
      Record<string, unknown>[] = [];

    const duplicateAmbiguousSamples:
      Record<string, unknown>[] = [];

    const duplicateUnresolvedSamples:
      Record<string, unknown>[] = [];

    const finalLinkedRecords:
      Record<string, unknown>[] = [];

    for (const currentRecord of currentRecords) {
      const currentMobile =
        normaliseMobile(
          currentRecord.mobile_no
        );

      if (!currentMobile) {
        continue;
      }

      const matches =
        preGeoByMobile.get(
          currentMobile
        );

      if (
        !matches ||
        matches.length === 0
      ) {
        mobileNotMatched++;
        continue;
      }

      exactMobileMatched++;

      if (matches.length > 1) {
        duplicateMobileMatches++;

        const currentName =
          normaliseName(
            currentRecord.name
          );

        const currentPs =
          normalisePoliceStation(
            currentRecord.ps_name
          );

        const exactNamePsCandidates =
          matches.filter((record) => {
            const candidateName =
              normaliseName(
                record.Name
              );

            const candidatePs =
              normalisePoliceStation(
                record.PoliceStation
              );

            const nameMatches =
              currentName !== "" &&
              candidateName !== "" &&
              currentName ===
                candidateName;

            const psMatches =
              currentPs !== "" &&
              candidatePs !== "" &&
              currentPs ===
                candidatePs;

            return (
              nameMatches &&
              psMatches
            );
          });

        const candidateSummary =
          matches
            .slice(0, 20)
            .map(
              (record) => ({
                Reg_No:
                  record.Reg_No,
                Name:
                  record.Name,
                Mobile_No:
                  record.Mobile_No,
                PoliceStation:
                  record.PoliceStation,
                Latitude:
                  record.Latitude,
                Longitude:
                  record.Longitude,
                normalisedName:
                  normaliseName(
                    record.Name
                  ),
                normalisedPoliceStation:
                  normalisePoliceStation(
                    record.PoliceStation
                  ),
              })
            );

        const duplicateBase = {
          gpid:
            currentRecord.unique_id,
          refNo:
            currentRecord.ref_no,
          currentName:
            currentRecord.name,
          currentMobile:
            currentRecord.mobile_no,
          currentPoliceStation:
            currentRecord.ps_name,
          normalisedCurrentName:
            currentName,
          normalisedCurrentPoliceStation:
            currentPs,
          numberOf2025Records:
            matches.length,
          exactNamePsCandidateCount:
            exactNamePsCandidates.length,
          candidates:
            candidateSummary,
        };

        if (
          exactNamePsCandidates.length === 1
        ) {
          duplicateMobileResolvedUnique++;

          const resolvedRecord =
            exactNamePsCandidates[0];

          finalLinkedRecords.push({
            gpid:
              currentRecord.unique_id,
            refNo:
              currentRecord.ref_no,
            currentName:
              currentRecord.name,
            currentMobile:
              currentRecord.mobile_no,
            currentPoliceStation:
              currentRecord.ps_name,
            matchType:
              "DUPLICATE_MOBILE_RESOLVED_UNIQUE_NAME_AND_PS",
            preGeo2025RegNo:
              resolvedRecord.Reg_No,
            preGeo2025Latitude:
              resolvedRecord.Latitude,
            preGeo2025Longitude:
              resolvedRecord.Longitude,
            preGeo2025Name:
              resolvedRecord.Name,
            preGeo2025Mobile:
              resolvedRecord.Mobile_No,
            preGeo2025PoliceStation:
              resolvedRecord.PoliceStation,
          });

          {
            duplicateResolvedSamples.push({
              ...duplicateBase,
              resolution:
                "RESOLVED_UNIQUE_NAME_AND_PS",
              matched2025Record: {
                Reg_No:
                  resolvedRecord.Reg_No,
                Name:
                  resolvedRecord.Name,
                Mobile_No:
                  resolvedRecord.Mobile_No,
                PoliceStation:
                  resolvedRecord.PoliceStation,
                Latitude:
                  resolvedRecord.Latitude,
                Longitude:
                  resolvedRecord.Longitude,
              },
            });
          }
        } else if (
          exactNamePsCandidates.length > 1
        ) {
          duplicateMobileAmbiguous++;

          if (
            duplicateAmbiguousSamples.length <
            20
          ) {
            duplicateAmbiguousSamples.push({
              ...duplicateBase,
              resolution:
                "AMBIGUOUS_MULTIPLE_NAME_AND_PS_MATCHES",
              matching2025Records:
                exactNamePsCandidates.map(
                  (record) => ({
                    Reg_No:
                      record.Reg_No,
                    Name:
                      record.Name,
                    Mobile_No:
                      record.Mobile_No,
                    PoliceStation:
                      record.PoliceStation,
                    Latitude:
                      record.Latitude,
                    Longitude:
                      record.Longitude,
                  })
                ),
            });
          }
        } else {
          duplicateMobileUnresolved++;

          if (
            duplicateUnresolvedSamples.length <
            20
          ) {
            duplicateUnresolvedSamples.push({
              ...duplicateBase,
              resolution:
                "UNRESOLVED_NO_EXACT_NAME_AND_PS_MATCH",
            });
          }
        }

        if (
          duplicateMobileSamples.length < 10
        ) {
          duplicateMobileSamples.push(
            duplicateBase
          );
        }

        continue;
      }

      uniqueMobileMatches++;

      const preGeoRecord =
        matches[0];

      const currentName =
        normaliseName(
          currentRecord.name
        );

      const preGeoName =
        normaliseName(
          preGeoRecord.Name
        );

      const currentPs =
        normalisePoliceStation(
          currentRecord.ps_name
        );

      const preGeoPs =
        normalisePoliceStation(
          preGeoRecord.PoliceStation
        );

      const nameMatches =
        currentName !== "" &&
        preGeoName !== "" &&
        currentName === preGeoName;

      const psMatches =
        currentPs !== "" &&
        preGeoPs !== "" &&
        currentPs === preGeoPs;

      const result = {
        gpid:
          currentRecord.unique_id,
        refNo:
          currentRecord.ref_no,
        currentName:
          currentRecord.name,
        preGeoName:
          preGeoRecord.Name,
        mobile:
          currentRecord.mobile_no,
        currentPoliceStation:
          currentRecord.ps_name,
        preGeoPoliceStation:
          preGeoRecord.PoliceStation,
        preGeoRegNo:
          preGeoRecord.Reg_No,
        latitude:
          preGeoRecord.Latitude,
        longitude:
          preGeoRecord.Longitude,
        nameMatch:
          nameMatches,
        policeStationMatch:
          psMatches,
      };

      if (
        nameMatches &&
        psMatches
      ) {
        uniqueMobileNamePsMatch++;

        if (
          strongMatches.length < 10
        ) {
          strongMatches.push(result);
        }

        finalLinkedRecords.push({
          gpid:
            currentRecord.unique_id,
          refNo:
            currentRecord.ref_no,
          currentName:
            currentRecord.name,
          currentMobile:
            currentRecord.mobile_no,
          currentPoliceStation:
            currentRecord.ps_name,
          matchType:
            "UNIQUE_MOBILE_NAME_AND_PS",
          preGeo2025RegNo:
            preGeoRecord.Reg_No,
          preGeo2025Latitude:
            preGeoRecord.Latitude,
          preGeo2025Longitude:
            preGeoRecord.Longitude,
          preGeo2025Name:
            preGeoRecord.Name,
          preGeo2025Mobile:
            preGeoRecord.Mobile_No,
          preGeo2025PoliceStation:
            preGeoRecord.PoliceStation,
        });

        continue;
      }

      if (
        nameMatches &&
        !psMatches
      ) {
        uniqueMobileNameOnlyMatch++;

        const psAnalysis =
          policeStationSimilarity(
            currentPs,
            preGeoPs
          );

        const analysedResult = {
          ...result,
          normalisedCurrentPoliceStation:
            currentPs,
          normalisedPreGeoPoliceStation:
            preGeoPs,
          policeStationEditDistance:
            psAnalysis.editDistance,
          policeStationSimilarityRatio:
            psAnalysis.similarityRatio,
          likelySamePoliceStation:
            psAnalysis.likelySamePoliceStation,
        };

        if (
          psAnalysis.likelySamePoliceStation
        ) {
          nameOnlyLikelySamePs++;

          const pairKey =
            `${currentPs}=>${preGeoPs}`;

          const existingPair =
            likelySamePsPairCounts.get(
              pairKey
            );

          if (existingPair) {
            existingPair.count++;
          } else {
            likelySamePsPairCounts.set(
              pairKey,
              {
                currentPoliceStation:
                  String(
                    currentRecord.ps_name ??
                      ""
                  ),
                preGeoPoliceStation:
                  String(
                    preGeoRecord.PoliceStation ??
                      ""
                  ),
                normalisedCurrentPoliceStation:
                  currentPs,
                normalisedPreGeoPoliceStation:
                  preGeoPs,
                editDistance:
                  psAnalysis.editDistance,
                similarityRatio:
                  psAnalysis.similarityRatio,
                count: 1,
              }
            );
          }

          if (
            likelySamePsSamples.length < 10
          ) {
            likelySamePsSamples.push(
              analysedResult
            );
          }
        } else {
          nameOnlyDifferentPs++;

          if (
            differentPsSamples.length < 10
          ) {
            differentPsSamples.push(
              analysedResult
            );
          }
        }

        if (
          nameOnlyMatches.length < 10
        ) {
          nameOnlyMatches.push(
            analysedResult
          );
        }

        continue;
      }

      if (
        !nameMatches &&
        psMatches
      ) {
        uniqueMobilePsOnlyMatch++;

        if (
          psOnlyMatches.length < 10
        ) {
          psOnlyMatches.push(
            result
          );
        }

        continue;
      }

      uniqueMobileNeitherMatch++;

      if (
        neitherMatches.length < 10
      ) {
        neitherMatches.push(
          result
        );
      }
    }

    const likelySamePsPairSummary =
      Array.from(
        likelySamePsPairCounts.values()
      ).sort(
        (a, b) =>
          b.count - a.count ||
          a.normalisedCurrentPoliceStation.localeCompare(
            b.normalisedCurrentPoliceStation
          )
      );

    return Response.json(
      {
        summary: {
          preGeo2025Total:
            preGeoRecords.length,
          current2026Total:
            currentRecords.length,
          exactMobileMatched,
          uniqueMobileMatches,
          duplicateMobileMatches,
          duplicateMobileResolvedUnique,
          duplicateMobileAmbiguous,
          duplicateMobileUnresolved,
          mobileNotMatched,
          uniqueMobileNamePsMatch,
          uniqueMobileNameOnlyMatch,
          uniqueMobilePsOnlyMatch,
          uniqueMobileNeitherMatch,

          nameOnlyLikelySamePs,
          nameOnlyDifferentPs,

          likelySamePsPairCount:
            likelySamePsPairSummary.length,

          potentialStrongMatchesIfLikelySamePsAccepted:
            uniqueMobileNamePsMatch +
            nameOnlyLikelySamePs,

          totalSafeMatchesIncludingResolvedDuplicates:
            uniqueMobileNamePsMatch +
            duplicateMobileResolvedUnique,

          finalLinkedRecordCount:
            finalLinkedRecords.length,

          duplicateResolutionRule:
            "When a 2026 mobile number matches multiple 2025 records, resolve automatically only when exactly one candidate matches both normalized applicant name and normalized/confirmed-alias police station. Zero matches remain unresolved; more than one match remains ambiguous. No application data is changed.",

          classificationRule:
            "For Mobile + Name matches where Police Station is not exact: likely same PS only when normalized PS names are at least 6 characters, Levenshtein edit distance <= 2, and similarity ratio >= 0.80. This is analysis only and does not alter application data.",

          validationLogic:
            "First exact normalized mobile match. For unique mobile matches, validate normalized applicant name and police station. For duplicate-mobile cases, compare every 2025 candidate and resolve only when exactly one candidate matches both normalized name and normalized/confirmed-alias police station. Name-only unique-mobile records are further classified using conservative spelling similarity. No application data is changed.",
        },

        likelySamePsPairSummary,
        strongMatches,
        nameOnlyMatches,
        likelySamePsSamples,
        differentPsSamples,
        psOnlyMatches,
        neitherMatches,
        duplicateMobileSamples,
        duplicateResolvedSamples,
        duplicateAmbiguousSamples,
        duplicateUnresolvedSamples,
        finalLinkedRecords,
      },
      {
        status: 200,
        headers: {
          "Access-Control-Allow-Origin":
            "*",
          "Cache-Control":
            "no-store",
        },
      }
    );
  } catch (error) {
    console.error(
      "Pre-Geo validation error:",
      error
    );

    return Response.json(
      {
        error:
          "Unable to validate 2026 records against 2025 Pre-Geo data",
        details:
          error instanceof Error
            ? error.message
            : String(error),
      },
      {
        status: 500,
      }
    );
  }
}

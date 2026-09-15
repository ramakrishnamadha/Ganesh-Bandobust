import { PrismaBetterSqlite3 } from "@prisma/adapter-better-sqlite3";
import { PrismaClient } from "../src/generated/prisma/client";

const adapter = new PrismaBetterSqlite3({
  url:
    process.env.DATABASE_URL ??
    "file:./dev.db",
});

const prisma = new PrismaClient({
  adapter,
});

type AccessConfig =
  | {
      employeeId: string;
      scope: "ADMIN";
      policeStations?: never;
    }
  | {
      employeeId: string;
      scope: "ZONE_ALL_PS";
      policeStations?: never;
    }
  | {
      employeeId: string;
      scope: "SPECIFIC_PS";
      policeStations: string[];
    };

/*
 * IMPORTANT ACCESS RULE
 *
 * "Police Stations can access" is the final authority.
 *
 * SPECIFIC_PS:
 *   User can VIEW + EDIT only the listed Police Stations.
 *
 * ZONE_ALL_PS:
 *   "All Police Stations" from the source sheet, but
 *   restricted to the Zone already assigned to that user.
 *
 * ADMIN:
 *   All Police Stations, all Divisions and all Zones.
 *
 * This script DOES NOT:
 * - Create users
 * - Reset passwords
 * - Change password hashes
 * - Change mustChangePassword
 */

const accessConfigs: AccessConfig[] = [
  // =====================================================
  // ADMINS — ALL DATA
  // =====================================================
  {
    employeeId: "3101682",
    scope: "ADMIN",
  },
  {
    employeeId: "1837323",
    scope: "ADMIN",
  },
  {
    employeeId: "2595447",
    scope: "ADMIN",
  },

  // =====================================================
  // ZONE USERS — ALL POLICE STATIONS OF THEIR ZONE
  // =====================================================
  {
    employeeId: "4510995",
    scope: "ZONE_ALL_PS",
  },
  {
    employeeId: "4502438",
    scope: "ZONE_ALL_PS",
  },
  {
    employeeId: "2162897",
    scope: "ZONE_ALL_PS",
  },
  {
    employeeId: "4502420",
    scope: "ZONE_ALL_PS",
  },
  {
    employeeId: "4502336",
    scope: "ZONE_ALL_PS",
  },
  {
    employeeId: "4502328",
    scope: "ZONE_ALL_PS",
  },
  {
    employeeId: "4502352",
    scope: "ZONE_ALL_PS",
  },

  // =====================================================
  // RAJENDRANAGAR / SHAMSHABAD
  // =====================================================
  {
    employeeId: "2608357",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Chandrayangutta",
      "Bandlaguda",
      "Kanchanbagh",
      "Mailardevpally",
    ],
  },
  {
    employeeId: "4503751",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Chandrayangutta",
      "Bandlaguda",
      "Kanchanbagh",
      "Mailardevpally",
    ],
  },
  {
    employeeId: "3501140",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Falaknuma",
      "Kamatipura",
      "Bahadurpura",
      "Kalapathar",
    ],
  },
  {
    employeeId: "2607966",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Rajendanagar",
      "Attapur",
    ],
  },
  {
    employeeId: "1414873",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Rajendanagar",
      "Attapur",
    ],
  },
  {
    employeeId: "2608434",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Rajendanagar",
      "Attapur",
    ],
  },
  {
    employeeId: "2604628",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Pahadishareef",
      "RGIA",
      "RGIA-OP",
    ],
  },
  {
    employeeId: "2582278",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Pahadishareef",
      "RGIA",
      "RGIA-OP",
    ],
  },

  {
    employeeId: "2607416",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Meerpet",
      "Adibatla",
      "Balapur",
    ],
  },
  {
    employeeId: "4502074",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Meerpet",
      "Adibatla",
      "Balapur",
    ],
  },
  {
    employeeId: "2607479",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Meerpet",
      "Adibatla",
      "Balapur",
    ],
  },
  {
    employeeId: "2608085",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Meerpet",
      "Adibatla",
      "Balapur",
    ],
  },
  {
    employeeId: "3501532",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Meerpet",
      "Adibatla",
      "Balapur",
    ],
  },
  {
    employeeId: "2607526",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Meerpet",
      "Adibatla",
      "Balapur",
    ],
  },

  // =====================================================
  // GOLCONDA ZONE
  // =====================================================
  {
    employeeId: "2608207",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Kulsumpura",
      "Gudimalkapur",
      "Mangalhat",
      "Tappachabutra",
    ],
  },
  {
    employeeId: "4502015",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Kulsumpura",
      "Gudimalkapur",
      "Mangalhat",
      "Tappachabutra",
    ],
  },
  {
    employeeId: "2607436",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Kulsumpura",
      "Gudimalkapur",
      "Mangalhat",
      "Tappachabutra",
    ],
  },
  {
    employeeId: "2607530",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Kulsumpura",
      "Gudimalkapur",
      "Mangalhat",
      "Tappachabutra",
    ],
  },

  {
    employeeId: "2607380",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Begumbazar",
      "Goshamahal",
      "Afzal Gunj",
    ],
  },
  {
    employeeId: "2593654",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Begumbazar",
      "Goshamahal",
      "Afzal Gunj",
    ],
  },
  {
    employeeId: "2607880",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Begumbazar",
      "Goshamahal",
      "Afzal Gunj",
    ],
  },

  {
    employeeId: "3501594",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Masabtank",
      "Asif Nagar",
      "Mehdipatnam",
      "Habeeb Nagar",
    ],
  },
  {
    employeeId: "2585248",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Masabtank",
      "Asif Nagar",
      "Mehdipatnam",
      "Habeeb Nagar",
    ],
  },

  {
    employeeId: "2607869",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Toli Chowki",
      "Golconda",
      "Langar House",
    ],
  },

  // =====================================================
  // JUBILEE HILLS ZONE
  // =====================================================
  {
    employeeId: "2607713",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Banjara Hills",
      "Madhura Nagar",
      "Jubilee Hills",
    ],
  },
  {
    employeeId: "2583051",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Banjara Hills",
      "Madhura Nagar",
      "Jubilee Hills",
    ],
  },

  {
    employeeId: "2607493",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Film Nagar",
    ],
  },
  {
    employeeId: "2608714",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Film Nagar",
    ],
  },

  {
    employeeId: "2607498",
    scope: "SPECIFIC_PS",
    policeStations: [
      "SR Nagar",
      "Borabanda",
      "Sanath Nagar",
    ],
  },
  {
    employeeId: "2608200",
    scope: "SPECIFIC_PS",
    policeStations: [
      "SR Nagar",
      "Borabanda",
      "Sanath Nagar",
    ],
  },
  {
    employeeId: "2583271",
    scope: "SPECIFIC_PS",
    policeStations: [
      "SR Nagar",
      "Borabanda",
      "Sanath Nagar",
    ],
  },
  {
    employeeId: "4513374",
    scope: "SPECIFIC_PS",
    policeStations: [
      "SR Nagar",
      "Borabanda",
      "Sanath Nagar",
    ],
  },

  // =====================================================
  // CHARMINAR ZONE
  // =====================================================
  {
    employeeId: "4502014",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Charminar",
      "Hussainialam",
      "Moghalpura",
      "Shalibanda",
    ],
  },

  {
    employeeId: "2607318",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Malakpet",
      "Chaderghat",
      "Dabeerpura",
    ],
  },
  {
    employeeId: "2608333",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Malakpet",
      "Chaderghat",
      "Dabeerpura",
    ],
  },

  {
    employeeId: "3501374",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Mirchowk",
      "Bhavani Nagar",
      "Rein Bazar",
    ],
  },

  {
    employeeId: "2607635",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Saidabad",
      "Madannapet",
    ],
  },
  {
    employeeId: "2584532",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Saidabad",
      "Madannapet",
    ],
  },

  {
    employeeId: "2607753",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Santosh Nagar",
      "IS Sadan",
      "Chatrinaka",
    ],
  },
  {
    employeeId: "2607586",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Santosh Nagar",
      "IS Sadan",
      "Chatrinaka",
    ],
  },
  {
    employeeId: "3500746",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Santosh Nagar",
      "IS Sadan",
      "Chatrinaka",
    ],
  },

  {
    employeeId: "4503670",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Charminar",
      "Hussainialam",
      "Moghalpura",
      "Shalibanda",
    ],
  },

  // =====================================================
  // SECUNDERABAD ZONE
  // =====================================================
  {
    employeeId: "2607403",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Mahankali",
      "Ramgopalpet",
    ],
  },

  {
    employeeId: "2608633",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Chikkadpally",
      "Musheerabad",
      "Kachiguda",
    ],
  },
  {
    employeeId: "4501821",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Chikkadpally",
      "Musheerabad",
      "Kachiguda",
    ],
  },
  {
    employeeId: "2607705",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Chikkadpally",
      "Musheerabad",
      "Kachiguda",
    ],
  },

  {
    employeeId: "2608318",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Gandhi Nagar",
      "Domalguda",
    ],
  },
  {
    employeeId: "3501640",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Gandhi Nagar",
      "Domalguda",
    ],
  },

  {
    employeeId: "2607427",
    scope: "SPECIFIC_PS",
    policeStations: [
      "OU Sity",
      "Nallakunta",
      "Amberpet",
    ],
  },
  {
    employeeId: "2585227",
    scope: "SPECIFIC_PS",
    policeStations: [
      "OU Sity",
      "Nallakunta",
      "Amberpet",
    ],
  },
  {
    employeeId: "2608093",
    scope: "SPECIFIC_PS",
    policeStations: [
      "OU Sity",
      "Nallakunta",
      "Amberpet",
    ],
  },
  {
    employeeId: "2607357",
    scope: "SPECIFIC_PS",
    policeStations: [
      "OU Sity",
      "Nallakunta",
      "Amberpet",
    ],
  },

  {
    employeeId: "2608043",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Chilkalguda",
      "Lallaguda",
      "Warasiguda",
    ],
  },
  {
    employeeId: "2608755",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Chilkalguda",
      "Lallaguda",
      "Warasiguda",
    ],
  },
  {
    employeeId: "2608033",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Chilkalguda",
      "Lallaguda",
      "Warasiguda",
    ],
  },
  {
    employeeId: "2608424",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Chilkalguda",
      "Lallaguda",
      "Warasiguda",
    ],
  },

  // =====================================================
  // KHAIRATABAD ZONE
  // =====================================================
  {
    employeeId: "4501775",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Abids",
      "Nampally",
    ],
  },

  {
    employeeId: "2607401",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Lake",
      "Saifabad",
      "Panjagutta",
      "Khairatabad",
    ],
  },

  {
    employeeId: "2608955",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Lake",
      "Saifabad",
      "Panjagutta",
      "Khairatabad",
    ],
  },

  {
    employeeId: "3501586",
    scope: "SPECIFIC_PS",
    policeStations: [
      "Sultan bazar",
      "Narayanguda",
    ],
  },
];

function normalizePoliceStationName(
  value: string,
): string {
  return value
    .replace(/\s+/g, " ")
    .replace(/\s+PS$/i, "")
    .trim();
}

async function main() {
  console.log("");
  console.log(
    "==============================================",
  );
  console.log(
    "GANESH USER POLICE STATION ACCESS IMPORT",
  );
  console.log(
    "==============================================",
  );
  console.log("");

  let updatedUsers = 0;
  let missingUsers = 0;
  let accessRowsCreated = 0;

  for (const config of accessConfigs) {
    const user =
      await prisma.user.findUnique({
        where: {
          employeeId:
            config.employeeId,
        },
      });

    if (!user) {
      console.warn(
        `USER NOT FOUND: ${config.employeeId}`,
      );

      missingUsers += 1;
      continue;
    }

    await prisma.$transaction(
      async (tx) => {
        /*
         * Always clear the user's old explicit PS assignments.
         *
         * This makes the script safe to re-run whenever
         * the official mapping is updated.
         */
        await tx.userPoliceStationAccess.deleteMany({
          where: {
            userId: user.id,
          },
        });

        if (
          config.scope === "ADMIN"
        ) {
          await tx.user.update({
            where: {
              id: user.id,
            },
            data: {
              allPoliceStations:
                true,
              allDivisions:
                true,
              allZones:
                true,
              allRanges:
                true,
            },
          });

          return;
        }

        if (
          config.scope ===
          "ZONE_ALL_PS"
        ) {
          await tx.user.update({
            where: {
              id: user.id,
            },
            data: {
              allPoliceStations:
                true,
              allDivisions:
                true,
              allZones:
                false,
              allRanges:
                false,
            },
          });

          return;
        }

        /*
         * Explicit Police Station access:
         *
         * User sees and edits ONLY these PSs.
         */
        await tx.user.update({
          where: {
            id: user.id,
          },
          data: {
            allPoliceStations:
              false,
            allDivisions:
              false,
            allZones:
              false,
            allRanges:
              false,
          },
        });

        const uniquePoliceStations =
          Array.from(
            new Set(
              config.policeStations
                .map(
                  normalizePoliceStationName,
                )
                .filter(
                  (value) =>
                    value.length > 0,
                ),
            ),
          );

        if (
          uniquePoliceStations.length >
          0
        ) {
          await tx.userPoliceStationAccess.createMany({
            data:
              uniquePoliceStations.map(
                (
                  policeStationName,
                ) => ({
                  userId:
                    user.id,

                  policeStationName,

                  policeStationCode:
                    null,

                  canView:
                    true,

                  canEdit:
                    true,
                }),
              ),
          });

          accessRowsCreated +=
            uniquePoliceStations.length;
        }
      },
    );

    updatedUsers += 1;

    if (
      config.scope === "ADMIN"
    ) {
      console.log(
        `ADMIN      ${config.employeeId} - ${user.name}`,
      );
    } else if (
      config.scope ===
      "ZONE_ALL_PS"
    ) {
      console.log(
        `ZONE ALL   ${config.employeeId} - ${user.name} - ${user.zoneName ?? "NO ZONE"}`,
      );
    } else {
      console.log(
        `SPECIFIC   ${config.employeeId} - ${user.name} - ${config.policeStations.join(", ")}`,
      );
    }
  }

  console.log("");
  console.log(
    "==============================================",
  );
  console.log(
    "ACCESS IMPORT COMPLETED",
  );
  console.log(
    "==============================================",
  );

  console.log(
    `Users updated       : ${updatedUsers}`,
  );

  console.log(
    `PS access rows added: ${accessRowsCreated}`,
  );

  console.log(
    `Users not found     : ${missingUsers}`,
  );

  console.log("");
  console.log(
    "No passwords were changed.",
  );
  console.log(
    "No users were created or deleted.",
  );
  console.log("");
}

main()
  .catch((error) => {
    console.error(
      "Police Station access import failed:",
      error,
    );

    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
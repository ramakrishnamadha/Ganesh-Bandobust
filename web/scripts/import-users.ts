import {
  randomBytes,
  scryptSync,
} from "node:crypto";

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

const DEFAULT_PASSWORD =
  "Ganesh@2026";

const COMMISSIONERATE_NAME =
  "Hyderabad Commissionerate";

type SourceOfficer = {
  employeeId: string;
  name: string;
  rank: string;
  phoneNumber: string;
  team: string;
  sourceRole: "Admin" | "DCP" | "ACP";
  division?: string;
  zone?: string;
};

const officers: SourceOfficer[] = [
  {
    employeeId: "3101682",
    name: "Avinash Kumar",
    rank: "DCP",
    phoneNumber: "8712661004",
    team: "I/C SMIT",
    sourceRole: "Admin",
  },
  {
    employeeId: "1837323",
    name: "M Rama Krishna",
    rank: "INSPECTOR",
    phoneNumber: "8712660777",
    team: "ADMIN INCHARGE INSP",
    sourceRole: "Admin",
  },
  {
    employeeId: "2595447",
    name: "S Naresh",
    rank: "INSPECTOR",
    phoneNumber: "8712660775",
    team: "CAT & Application I/C",
    sourceRole: "Admin",
  },

  {
    employeeId: "4510995",
    name: "Dhudu Sravanthi",
    rank: "SI",
    phoneNumber: "8179792965",
    team: "CCC Incharge",
    sourceRole: "DCP",
    zone: "Jubilee Hills",
  },
  {
    employeeId: "4502438",
    name: "B. Nikitha",
    rank: "SI",
    phoneNumber: "8712571804",
    team: "Applications",
    sourceRole: "DCP",
    zone: "Golconda",
  },
  {
    employeeId: "2162897",
    name: "Siddagoni Shanti",
    rank: "SI",
    phoneNumber: "9490451913",
    team: "Admin Team",
    sourceRole: "DCP",
    zone: "Charminar",
  },
  {
    employeeId: "4502420",
    name: "K.Bhavana",
    rank: "SI",
    phoneNumber: "8712572073",
    team: "SMU",
    sourceRole: "DCP",
    zone: "Khairatabad",
  },
  {
    employeeId: "4502336",
    name: "Gunna Shruthi",
    rank: "SI",
    phoneNumber: "8712572031",
    team: "Admin",
    sourceRole: "DCP",
    zone: "Rajendranagar",
  },
  {
    employeeId: "4502328",
    name: "K.Akhila",
    rank: "SI",
    phoneNumber: "8712571805",
    team: "CAT",
    sourceRole: "DCP",
    zone: "Secunderabad",
  },
  {
    employeeId: "4502352",
    name: "Penta Venkata Sai Abhishek",
    rank: "SI",
    phoneNumber: "8712572133",
    team: "CAT",
    sourceRole: "DCP",
    zone: "Shamshabad",
  },

  {
    employeeId: "2608357",
    name: "G. Sunil Kumar",
    rank: "PC",
    phoneNumber: "8712516532",
    team: "IT CORE",
    sourceRole: "DCP",
    division: "Chandrayangutta",
    zone: "Rajendranagar",
  },
  {
    employeeId: "4503751",
    name: "Anil Kumar",
    rank: "PC",
    phoneNumber: "8712521598",
    team: "CAT",
    sourceRole: "ACP",
    division: "Chandrayangutta",
  },
  {
    employeeId: "3501140",
    name: "P Madhukar Rao",
    rank: "PC",
    phoneNumber: "9948115254",
    team: "CCC",
    sourceRole: "ACP",
    division: "Falaknuma",
  },
  {
    employeeId: "2607966",
    name: "M.Ravinder Kumar",
    rank: "PC",
    phoneNumber: "9603318678",
    team: "CCTV",
    sourceRole: "ACP",
    division: "Rajendranagar",
  },
  {
    employeeId: "1414873",
    name: "Vara Prasad",
    rank: "HC",
    phoneNumber: "8712684460",
    team: "IT CORE",
    sourceRole: "DCP",
    division: "Rajendranagar",
    zone: "Rajendranagar",
  },
  {
    employeeId: "2608434",
    name: "D. Naveen Kumar",
    rank: "PC",
    phoneNumber: "9573909999",
    team: "SMGC",
    sourceRole: "ACP",
    division: "Rajendranagar",
  },
  {
    employeeId: "2604628",
    name: "Mohd Obaid Akram",
    rank: "PC",
    phoneNumber: "8712517195",
    team: "IT CORE",
    sourceRole: "DCP",
    division: "Pahadishareef",
    zone: "Shamshabad",
  },
  {
    employeeId: "2582278",
    name: "Sai Charan",
    rank: "PC",
    phoneNumber: "9949655149",
    team: "CCS",
    sourceRole: "ACP",
    division: "Pahadishareef",
  },
  {
    employeeId: "2607416",
    name: "Raja Shekar",
    rank: "PC",
    phoneNumber: "8247092566",
    team: "Admin",
    sourceRole: "ACP",
    division: "Adibatla",
  },
  {
    employeeId: "4502074",
    name: "Vipul Sai",
    rank: "PC",
    phoneNumber: "7729953761",
    team: "IT Core",
    sourceRole: "DCP",
    division: "Adibatla",
    zone: "Shamshabad",
  },
  {
    employeeId: "2607479",
    name: "G.Srikanth",
    rank: "PC",
    phoneNumber: "8712514264",
    team: "Writer",
    sourceRole: "ACP",
    division: "Adibatla",
  },
  {
    employeeId: "2608085",
    name: "Yeshwanth",
    rank: "PC",
    phoneNumber: "9985658551",
    team: "HRMS",
    sourceRole: "ACP",
    division: "Adibatla",
  },
  {
    employeeId: "3501532",
    name: "V. Srinivas",
    rank: "PC",
    phoneNumber: "8712518295",
    team: "SR - Section",
    sourceRole: "ACP",
    division: "Adibatla",
  },
  {
    employeeId: "2607526",
    name: "G. Prabhakar",
    rank: "PC",
    phoneNumber: "8712514665",
    team: "Pension",
    sourceRole: "ACP",
    division: "Adibatla",
  },

  {
    employeeId: "2608207",
    name: "P.Arun Kumar",
    rank: "PC",
    phoneNumber: "8712664799",
    team: "CCTV",
    sourceRole: "ACP",
    division: "Kulsumpura",
  },
  {
    employeeId: "4502015",
    name: "R Ramesh",
    rank: "PC",
    phoneNumber: "8712519956",
    team: "Networking",
    sourceRole: "ACP",
    division: "Kulsumpura",
  },
  {
    employeeId: "2607436",
    name: "Manohar",
    rank: "PC",
    phoneNumber: "9247676035",
    team: "IT Core",
    sourceRole: "DCP",
    division: "Kulsumpura",
    zone: "Golconda",
  },
  {
    employeeId: "2607530",
    name: "A Venkatesh",
    rank: "PC",
    phoneNumber: "9014602012",
    team: "Applications",
    sourceRole: "ACP",
    division: "Kulsumpura",
  },
  {
    employeeId: "2607380",
    name: "V.Santosh",
    rank: "PC",
    phoneNumber: "9502030570",
    team: "IT Core",
    sourceRole: "DCP",
    division: "Goshamahal",
    zone: "Golconda",
  },
  {
    employeeId: "2593654",
    name: "P. Dorababu",
    rank: "PC",
    phoneNumber: "9441704177",
    team: "Att. To HQrs",
    sourceRole: "ACP",
    division: "Goshamahal",
  },
  {
    employeeId: "2607880",
    name: "T. Sandeep Kumar",
    rank: "PC",
    phoneNumber: "9030292304",
    team: "Att. To ICCC Building",
    sourceRole: "ACP",
    division: "Goshamahal",
  },
  {
    employeeId: "3501594",
    name: "CH.Dheeraj Kumar",
    rank: "PC",
    phoneNumber: "9390634198",
    team: "CCTV",
    sourceRole: "ACP",
    division: "Asif Nagar",
  },
  {
    employeeId: "2585248",
    name: "S.B.Nagendra",
    rank: "PC",
    phoneNumber: "8712517143",
    team: "Admin",
    sourceRole: "ACP",
    division: "Asif Nagar",
  },
  {
    employeeId: "2607869",
    name: "M Bhaskar",
    rank: "PC",
    phoneNumber: "8712664814",
    team: "CCTV",
    sourceRole: "ACP",
    division: "Toli Chowki",
  },

  {
    employeeId: "2607713",
    name: "S Sandeep",
    rank: "PC",
    phoneNumber: "8712515144",
    team: "CCTV",
    sourceRole: "ACP",
    division: "Banjara Hills",
  },
  {
    employeeId: "2583051",
    name: "Sri Kanth",
    rank: "PC",
    phoneNumber: "9666804516",
    team: "IT Core",
    sourceRole: "DCP",
    division: "Banjara Hills",
    zone: "Jubilee Hills",
  },
  {
    employeeId: "2607493",
    name: "Sampath",
    rank: "PC",
    phoneNumber: "8712664815",
    team: "CCTV",
    sourceRole: "ACP",
    division: "Jubilee Hills",
  },
  {
    employeeId: "2608714",
    name: "David Raj",
    rank: "PC",
    phoneNumber: "9959992890",
    team: "Admin Camp",
    sourceRole: "ACP",
    division: "Jubilee Hills",
  },
  {
    employeeId: "2607498",
    name: "S.Prudhviraj Goud",
    rank: "PC",
    phoneNumber: "8712664795",
    team: "CCTV",
    sourceRole: "ACP",
    division: "SR Nagar",
  },
  {
    employeeId: "2608200",
    name: "Shyam Sundar",
    rank: "PC",
    phoneNumber: "8121278239",
    team: "IT Core",
    sourceRole: "DCP",
    division: "SR Nagar",
    zone: "Jubilee Hills",
  },
  {
    employeeId: "2583271",
    name: "Achaiah Yadav",
    rank: "PC",
    phoneNumber: "8686832001",
    team: "CCC",
    sourceRole: "ACP",
    division: "SR Nagar",
  },
  {
    employeeId: "4513374",
    name: "Karthik",
    rank: "PC",
    phoneNumber: "7396603995",
    team: "CAT",
    sourceRole: "ACP",
    division: "SR Nagar",
  },

  {
    employeeId: "4502014",
    name: "MD.Waheeuddin",
    rank: "PC",
    phoneNumber: "8712419647",
    team: "CCC",
    sourceRole: "ACP",
    division: "Charminar",
  },
  {
    employeeId: "2607318",
    name: "Dhanunjay",
    rank: "PC",
    phoneNumber: "8712664789",
    team: "CCTV",
    sourceRole: "ACP",
    division: "Malakpet",
  },
  {
    employeeId: "2608333",
    name: "Ramesh",
    rank: "PC",
    phoneNumber: "8712664819",
    team: "IT Core",
    sourceRole: "DCP",
    division: "Malakpet",
    zone: "Charminar",
  },
  {
    employeeId: "3501374",
    name: "Ramesh",
    rank: "PC",
    phoneNumber: "8712518160",
    team: "HRMS",
    sourceRole: "ACP",
    division: "Mirchowk",
  },
  {
    employeeId: "2607635",
    name: "Ravi",
    rank: "PC",
    phoneNumber: "9059792614",
    team: "CCTV",
    sourceRole: "ACP",
    division: "Saidabad",
  },
  {
    employeeId: "2584532",
    name: "K.Santosh Kumar",
    rank: "PC",
    phoneNumber: "8179390007",
    team: "IT Core",
    sourceRole: "DCP",
    division: "Saidabad",
    zone: "Charminar",
  },
  {
    employeeId: "2607753",
    name: "Manoj",
    rank: "PC",
    phoneNumber: "9052431989",
    team: "IT Core",
    sourceRole: "DCP",
    division: "Santosh Nagar",
    zone: "Charminar",
  },
  {
    employeeId: "2607586",
    name: "Shiva Shankar",
    rank: "PC",
    phoneNumber: "8712514676",
    team: "CCC",
    sourceRole: "ACP",
    division: "Santosh Nagar",
  },
  {
    employeeId: "3500746",
    name: "Arun Kumar",
    rank: "PC",
    phoneNumber: "7013400095",
    team: "SR - Section",
    sourceRole: "ACP",
    division: "Santosh Nagar",
  },
  {
    employeeId: "4503670",
    name: "K.Nishanth Kumar",
    rank: "PC",
    phoneNumber: "9985998495",
    team: "MMU",
    sourceRole: "ACP",
    division: "Charminar",
  },

  {
    employeeId: "2607403",
    name: "Dilip",
    rank: "PC",
    phoneNumber: "8712664804",
    team: "CCTV",
    sourceRole: "ACP",
    division: "Mahankali",
  },
  {
    employeeId: "2608633",
    name: "Srinivas",
    rank: "PC",
    phoneNumber: "8712664792",
    team: "CCTV",
    sourceRole: "ACP",
    division: "Chikkadpally",
  },
  {
    employeeId: "4501821",
    name: "Madhu Sai",
    rank: "PC",
    phoneNumber: "7032403458",
    team: "Admin",
    sourceRole: "ACP",
    division: "Chikkadpally",
  },
  {
    employeeId: "2607705",
    name: "Sai Santosh",
    rank: "PC",
    phoneNumber: "9032222666",
    team: "CAT",
    sourceRole: "ACP",
    division: "Chikkadpally",
  },
  {
    employeeId: "2608318",
    name: "V.Gopal Krishna",
    rank: "PC",
    phoneNumber: "9603849002",
    team: "CCTV",
    sourceRole: "ACP",
    division: "Gandhi Nagar",
  },
  {
    employeeId: "3501640",
    name: "Venkat Reddy",
    rank: "PC",
    phoneNumber: "8074486790",
    team: "SR - Section",
    sourceRole: "ACP",
    division: "Gandhi Nagar",
  },

  {
    employeeId: "2607427",
    name: "Naresh",
    rank: "PC",
    phoneNumber: "8712660798",
    team: "Admin",
    sourceRole: "ACP",
    division: "OU Sity",
  },
  {
    employeeId: "2585227",
    name: "Praveen",
    rank: "PC",
    phoneNumber: "9848333817",
    team: "Admin",
    sourceRole: "ACP",
    division: "OU Sity",
  },
  {
    employeeId: "2608093",
    name: "Shiva Prasad",
    rank: "PC",
    phoneNumber: "9010895994",
    team: "Networking",
    sourceRole: "ACP",
    division: "OU Sity",
  },
  {
    employeeId: "2607357",
    name: "Vikranth",
    rank: "PC",
    phoneNumber: "8712514637",
    team: "IT Core",
    sourceRole: "DCP",
    division: "OU Sity",
    zone: "Secunderabad",
  },
  {
    employeeId: "2608043",
    name: "Shiva Prasad",
    rank: "PC",
    phoneNumber: "8712664801",
    team: "CCTV",
    sourceRole: "ACP",
    division: "Chilkalguda",
  },
  {
    employeeId: "2608755",
    name: "Mahesh",
    rank: "PC",
    phoneNumber: "8712514171",
    team: "E- Office",
    sourceRole: "ACP",
    division: "Chilkalguda",
  },
  {
    employeeId: "2608033",
    name: "Sai Teja",
    rank: "PC",
    phoneNumber: "9533532482",
    team: "Applications",
    sourceRole: "ACP",
    division: "Chilkalguda",
  },
  {
    employeeId: "2608424",
    name: "Sudhakar",
    rank: "PC",
    phoneNumber: "9666652377",
    team: "IT Core",
    sourceRole: "DCP",
    division: "Chilkalguda",
    zone: "Secunderabad",
  },

  {
    employeeId: "4501775",
    name: "Mazar",
    rank: "PC",
    phoneNumber: "8712519927",
    team: "IT Core",
    sourceRole: "DCP",
    division: "Abids",
    zone: "Khairatabad",
  },
  {
    employeeId: "2607401",
    name: "Venu Yadav",
    rank: "PC",
    phoneNumber: "8712664797",
    team: "CCTV",
    sourceRole: "ACP",
    division: "Saifabad",
  },
  {
    employeeId: "2608955",
    name: "Ayan",
    rank: "PC",
    phoneNumber: "8712661602",
    team: "CCTV",
    sourceRole: "ACP",
    division: "Panjagutta",
  },
  {
    employeeId: "3501586",
    name: "Natraj",
    rank: "PC",
    phoneNumber: "8712518150",
    team: "IT Core",
    sourceRole: "DCP",
    division: "Sultan bazar",
    zone: "Khairatabad",
  },
];

function normalizeText(
  value?: string,
): string | null {
  if (!value) {
    return null;
  }

  const cleaned =
    value
      .replace(/\s+/g, " ")
      .trim();

  return cleaned.length > 0
    ? cleaned
    : null;
}

function hashPassword(
  password: string,
): string {
  const salt =
    randomBytes(16).toString(
      "hex",
    );

  const derivedKey =
    scryptSync(
      password,
      salt,
      64,
    );

  return [
    "scrypt",
    salt,
    derivedKey.toString("hex"),
  ].join("$");
}

function getRole(
  sourceRole: SourceOfficer["sourceRole"],
): {
  role: string;
  accessLevel: number;
} {
  switch (sourceRole) {
    case "Admin":
      return {
        role: "ADMIN",
        accessLevel: 7,
      };

    case "DCP":
      return {
        role: "ZONAL_SUPERVISOR",
        accessLevel: 5,
      };

    case "ACP":
      return {
        role: "DIVISIONAL_SUPERVISOR",
        accessLevel: 4,
      };
  }
}

async function main() {
  console.log(
    "Ganesh Bandobust user import",
  );

  console.log(
    `Source officers: ${officers.length}`,
  );

  console.log(
    "Username: Employee ID",
  );

  console.log(
    "First-login password change: REQUIRED",
  );

  const seenEmployeeIds =
    new Set<string>();

  let created = 0;
  let updated = 0;
  let skipped = 0;

  for (const officer of officers) {
    const employeeId =
      officer.employeeId
        .replace(/[^0-9A-Za-z_-]/g, "")
        .trim();

    if (!employeeId) {
      console.warn(
        `SKIPPED: ${officer.name} has no valid Employee ID.`,
      );

      skipped += 1;
      continue;
    }

    if (
      seenEmployeeIds.has(
        employeeId,
      )
    ) {
      console.warn(
        `SKIPPED duplicate Employee ID: ${employeeId} (${officer.name})`,
      );

      skipped += 1;
      continue;
    }

    seenEmployeeIds.add(
      employeeId,
    );

    const {
      role,
      accessLevel,
    } = getRole(
      officer.sourceRole,
    );

    const divisionName =
      normalizeText(
        officer.division,
      );

    const zoneName =
      normalizeText(
        officer.zone,
      );

    /*
     * IMPORTANT:
     *
     * The supplied sheet contains names rather than the
     * official hierarchy codes. Therefore we preserve the
     * names here and leave the corresponding *Code fields
     * null.
     *
     * When the final Police Station / Division / Zone /
     * Range master is connected, we will populate the
     * official codes from that master instead of inventing
     * them.
     */

    const existing =
      await prisma.user.findUnique({
        where: {
          employeeId,
        },
      });

    if (existing) {
      /*
       * Do NOT reset an existing user's password during
       * re-import.
       *
       * This is important because a user may already have
       * changed the default password.
       */
      await prisma.user.update({
        where: {
          employeeId,
        },

        data: {
          username:
            employeeId,

          name:
            officer.name.trim(),

          rank:
            officer.rank.trim(),

          phoneNumber:
            officer.phoneNumber.trim(),

          team:
            officer.team.trim(),

          role,
          accessLevel,

          commissionerateName:
            COMMISSIONERATE_NAME,

          divisionName,
          zoneName,

          /*
           * The source sheet says "All Police Stations"
           * for these nominated supervisory accounts.
           * Their actual visibility is still constrained
           * by their Division/Zone/Admin scope.
           */
          allPoliceStations:
            true,

          allDivisions:
            role ===
              "ZONAL_SUPERVISOR" ||
            role === "ADMIN",

          allZones:
            role === "ADMIN",

          allRanges:
            role === "ADMIN",

          status:
            "ACTIVE",
        },
      });

      updated += 1;

      console.log(
        `UPDATED ${employeeId} - ${officer.name} - ${role}`,
      );

      continue;
    }

    const passwordHash =
      hashPassword(
        DEFAULT_PASSWORD,
      );

    await prisma.user.create({
      data: {
        employeeId,

        username:
          employeeId,

        passwordHash,

        name:
          officer.name.trim(),

        rank:
          officer.rank.trim(),

        phoneNumber:
          officer.phoneNumber.trim(),

        team:
          officer.team.trim(),

        role,
        accessLevel,

        mustChangePassword:
          true,

        commissionerateName:
          COMMISSIONERATE_NAME,

        divisionName,
        zoneName,

        allPoliceStations:
          true,

        allDivisions:
          role ===
            "ZONAL_SUPERVISOR" ||
          role === "ADMIN",

        allZones:
          role === "ADMIN",

        allRanges:
          role === "ADMIN",

        status:
          "ACTIVE",
      },
    });

    created += 1;

    console.log(
      `CREATED ${employeeId} - ${officer.name} - ${role}`,
    );
  }

  console.log("");
  console.log(
    "==========================================",
  );
  console.log(
    "USER IMPORT COMPLETED",
  );
  console.log(
    "==========================================",
  );
  console.log(
    `Created : ${created}`,
  );
  console.log(
    `Updated : ${updated}`,
  );
  console.log(
    `Skipped : ${skipped}`,
  );
  console.log(
    `Processed: ${created + updated + skipped}`,
  );
  console.log("");
  console.log(
    "All newly created users:",
  );
  console.log(
    "- Username = Employee ID",
  );
  console.log(
    "- Initial password configured",
  );
  console.log(
    "- Password stored only as scrypt hash",
  );
  console.log(
    "- mustChangePassword = true",
  );
}

main()
  .catch((error) => {
    console.error(
      "User import failed:",
      error,
    );

    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
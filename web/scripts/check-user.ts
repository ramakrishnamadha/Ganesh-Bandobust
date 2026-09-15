import { scryptSync, timingSafeEqual } from "node:crypto";

import { PrismaBetterSqlite3 } from "@prisma/adapter-better-sqlite3";
import { PrismaClient } from "../src/generated/prisma/client";

const prisma = new PrismaClient({
  adapter: new PrismaBetterSqlite3({
    url: "file:./dev.db",
  }),
});

function verifyPassword(
  password: string,
  storedHash: string,
): boolean {
  const parts = storedHash.split("$");

  if (parts.length !== 3) {
    return false;
  }

  const [algorithm, salt, hashHex] = parts;

  if (algorithm !== "scrypt") {
    return false;
  }

  const storedBuffer = Buffer.from(
    hashHex,
    "hex",
  );

  const derivedBuffer = scryptSync(
    password,
    salt,
    storedBuffer.length,
  );

  if (
    storedBuffer.length !==
    derivedBuffer.length
  ) {
    return false;
  }

  return timingSafeEqual(
    storedBuffer,
    derivedBuffer,
  );
}

async function main() {
  const user = await prisma.user.findUnique({
    where: {
      username: "1837323",
    },
    select: {
      username: true,
      name: true,
      passwordHash: true,
    },
  });

  if (!user) {
    console.log("User not found.");
    return;
  }

  const passwordToTest = "Ganesh@2026";

  const matches = verifyPassword(
    passwordToTest,
    user.passwordHash,
  );

  console.log({
    username: user.username,
    name: user.name,
    passwordTested: passwordToTest,
    passwordMatches: matches,
  });
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
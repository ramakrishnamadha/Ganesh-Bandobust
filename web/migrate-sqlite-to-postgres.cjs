const Database = require("better-sqlite3");
const { Client } = require("pg");
require("dotenv").config();

const sqlite = new Database("dev.db", { readonly: true });

const postgres = new Client({
  connectionString: process.env.DATABASE_URL,
});

const tables = [
  "User",
  "UserPoliceStationAccess",
  "PreInstallationVerification",
  "UserSession",
  "DeviceSession",
  "OfficerCurrentLocation",
  "OfficerLocationHistory",
  "ActivityEvent",
];

function quoteIdentifier(value) {
  return `"${String(value).replace(/"/g, '""')}"`;
}

function getColumnInfo(table) {
  return sqlite.prepare(`PRAGMA table_info(${quoteIdentifier(table)})`).all();
}

function convertValue(value, columnType) {
  if (value === null || value === undefined) {
    return null;
  }

  const type = String(columnType || "").toUpperCase();

  if (type === "BOOLEAN") {
    return Boolean(value);
  }

  return value;
}

async function migrateTable(table) {
  const columns = getColumnInfo(table);

  const columnNames = columns.map((column) => column.name);

  const rows = sqlite
    .prepare(`SELECT * FROM ${quoteIdentifier(table)}`)
    .all();

  console.log(`Migrating ${table}: ${rows.length} rows`);

  if (rows.length === 0) {
    return;
  }

  const quotedColumns = columnNames
    .map((column) => quoteIdentifier(column))
    .join(", ");

  const placeholders = columnNames
    .map((_, index) => `$${index + 1}`)
    .join(", ");

  const sql = `
    INSERT INTO ${quoteIdentifier(table)}
    (${quotedColumns})
    VALUES (${placeholders})
  `;

  for (const row of rows) {
    const values = columns.map((column) =>
      convertValue(row[column.name], column.type)
    );

    await postgres.query(sql, values);
  }
}

async function verifyPostgresIsEmpty() {
  for (const table of tables) {
    const result = await postgres.query(
      `SELECT COUNT(*)::int AS count FROM ${quoteIdentifier(table)}`
    );

    const count = result.rows[0].count;

    if (count !== 0) {
      throw new Error(
        `PostgreSQL table ${table} is not empty (${count} rows). Migration stopped.`
      );
    }
  }
}

async function resetVerificationSequence() {
  const result = await postgres.query(`
    SELECT pg_get_serial_sequence(
      '"PreInstallationVerification"',
      'id'
    ) AS sequence_name
  `);

  const sequenceName = result.rows[0]?.sequence_name;

  if (!sequenceName) {
    return;
  }

  await postgres.query(`
    SELECT setval(
      '${sequenceName}',
      COALESCE(
        (SELECT MAX("id") FROM "PreInstallationVerification"),
        1
      ),
      true
    )
  `);
}

async function printCounts(title, source) {
  console.log(`\n${title}`);

  for (const table of tables) {
    if (source === "sqlite") {
      const row = sqlite
        .prepare(
          `SELECT COUNT(*) AS count FROM ${quoteIdentifier(table)}`
        )
        .get();

      console.log(`${table}: ${row.count}`);
    } else {
      const result = await postgres.query(
        `SELECT COUNT(*)::int AS count FROM ${quoteIdentifier(table)}`
      );

      console.log(`${table}: ${result.rows[0].count}`);
    }
  }
}

async function main() {
  try {
    await postgres.connect();

    console.log("Connected to PostgreSQL.");

    await verifyPostgresIsEmpty();

    console.log("PostgreSQL target tables are empty.");

    await printCounts("SQLite BEFORE migration", "sqlite");

    await postgres.query("BEGIN");

    for (const table of tables) {
      await migrateTable(table);
    }

    await resetVerificationSequence();

    await postgres.query("COMMIT");

    console.log("\nMigration committed successfully.");

    await printCounts("PostgreSQL AFTER migration", "postgres");
  } catch (error) {
    try {
      await postgres.query("ROLLBACK");
    } catch (_) {}

    console.error("\nMIGRATION FAILED:");
    console.error(error);

    process.exitCode = 1;
  } finally {
    sqlite.close();

    try {
      await postgres.end();
    } catch (_) {}
  }
}

main();
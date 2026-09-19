import "dotenv/config";
import {
  getDefaultTargetRule,
  calculateOfficerDailyProgress,
} from "../src/lib/server/visitTargetEngine";

async function runTargetEngineTests() {
  console.log("=== Testing Phase 1: Core Target Engine ===");

  let passCount = 0;
  let failCount = 0;

  function assert(condition: boolean, description: string) {
    if (condition) {
      console.log(`[PASS] ${description}`);
      passCount++;
    } else {
      console.error(`[FAIL] ${description}`);
      failCount++;
    }
  }

  // Test 1: Cluster In-Charge target rule
  const clusterRule = getDefaultTargetRule("CLUSTER_INCHARGE");
  assert(clusterRule.frequencyPerMandap === 2, "Cluster In-charge requires 2 visits/day/mandap");
  assert(clusterRule.scopeLevel === "CLUSTER", "Cluster In-charge scope is CLUSTER");

  // Test 2: Sector In-Charge target rule
  const sectorRule = getDefaultTargetRule("SECTOR_INCHARGE");
  assert(sectorRule.frequencyPerMandap === 1, "Sector In-charge requires 1 visit/day/mandap");
  assert(sectorRule.scopeLevel === "SECTOR", "Sector In-charge scope is SECTOR");

  // Test 3: Detective Inspector target rule
  const diRule = getDefaultTargetRule("DI");
  assert(diRule.minMandapsPerUnit === 5, "DI requires min 5 mandaps per sector");

  // Test 4: ACP target rule
  const acpRule = getDefaultTargetRule("ACP");
  assert(acpRule.minMandapsPerUnit === 2, "ACP requires min 2 mandaps per PS");
  assert(acpRule.requiresSensitiveMandap === true, "ACP requires at least 1 sensitive mandap");

  // Test 5: Addl DCP target rule
  const addlDcpRule = getDefaultTargetRule("ADDL_DCP");
  assert(addlDcpRule.minMandapsPerUnit === 2, "Addl DCP requires min 2 mandaps per division");
  assert(addlDcpRule.requiresSensitiveMandap === true, "Addl DCP requires at least 1 sensitive mandap");

  // Test 6: Special Branch target rule
  const sbRule = getDefaultTargetRule("SB_PS");
  assert(sbRule.minMandapsPerUnit === 15, "PS SB requires min 15 mandaps");
  assert(sbRule.requiresSensitiveMandap === true, "SB requires sensitive mandaps");

  // Test 7: Night City SB rule
  const nightSbRule = getDefaultTargetRule("SB_NIGHT_CITY");
  assert(nightSbRule.shiftType === "NIGHT", "Night City SB is NIGHT shift");

  // Test 8: calculateOfficerDailyProgress with mock data
  try {
    const progress = await calculateOfficerDailyProgress({
      userId: "test_officer_001",
      officerEmployeeId: "EMP9901",
      officerName: "Constable Ramesh",
      officerRank: "PC",
      officerRole: "CLUSTER_INCHARGE",
      policeStationName: "Charminar",
      divisionName: "Charminar",
      zoneName: "Charminar",
      sectorName: "Sector 1",
      date: "2026-09-18",
      festivalDay: 4,
    });

    assert(progress.officerName === "Constable Ramesh", "Officer name preserved");
    assert(progress.status === "NOT_STARTED" || progress.status === "DEFICIT", "Initial status correctly flagged");
    assert(Array.isArray(progress.pendingMandaps), "Pending mandaps array returned");
    assert(Array.isArray(progress.completedMandaps), "Completed mandaps array returned");
  } catch (error) {
    console.error("calculateOfficerDailyProgress error:", error);
    assert(false, `calculateOfficerDailyProgress execution failed: ${error}`);
  }

  console.log(`\n=== Engine Test Results: ${passCount} passed, ${failCount} failed ===\n`);
  if (failCount > 0) process.exit(1);
}

runTargetEngineTests().catch((err) => {
  console.error("Test runner failed:", err);
  process.exit(1);
});

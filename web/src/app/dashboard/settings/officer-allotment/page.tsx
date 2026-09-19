import { redirect } from "next/navigation";

export default function OfficerAllotmentRedirectPage() {
  redirect("/dashboard/settings/role-allotment");
}

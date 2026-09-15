"use client";

import { useState } from "react";

type ChangePasswordResponse = {
  success: boolean;
  error?: string;
};

export default function ChangePasswordPage() {
  const [currentPassword, setCurrentPassword] =
    useState("");

  const [newPassword, setNewPassword] =
    useState("");

  const [confirmPassword, setConfirmPassword] =
    useState("");

  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [isSaving, setIsSaving] =
    useState(false);

  const handleChangePassword =
    async () => {
      if (isSaving) {
        return;
      }

      setError("");
      setSuccess("");

      if (
        !currentPassword ||
        !newPassword ||
        !confirmPassword
      ) {
        setError(
          "Enter current password, new password and confirm password.",
        );
        return;
      }

      if (
        newPassword.length < 8
      ) {
        setError(
          "New password must contain at least 8 characters.",
        );
        return;
      }

      if (
        newPassword ===
        currentPassword
      ) {
        setError(
          "New password must be different from the current password.",
        );
        return;
      }

      if (
        newPassword !==
        confirmPassword
      ) {
        setError(
          "New password and confirm password do not match.",
        );
        return;
      }

      setIsSaving(true);

      try {
        const response =
          await fetch(
            "/api/auth/change-password",
            {
              method: "POST",

              headers: {
                "Content-Type":
                  "application/json",
              },

              credentials:
                "include",

              body:
                JSON.stringify({
                  currentPassword,
                  newPassword,
                }),
            },
          );

        const data =
          (await response.json()) as ChangePasswordResponse;

        if (
          !response.ok ||
          !data.success
        ) {
          setError(
            data.error ??
              "Unable to change password.",
          );
          return;
        }

        setSuccess(
          "Password changed successfully. Redirecting to dashboard...",
        );

        /*
         * Update the local UI copy so the front end
         * no longer treats the officer as a
         * first-login user.
         */
        try {
          const storedUser =
            localStorage.getItem(
              "ganesh_user",
            );

          if (storedUser) {
            const user =
              JSON.parse(
                storedUser,
              ) as Record<
                string,
                unknown
              >;

            user.mustChangePassword =
              false;

            localStorage.setItem(
              "ganesh_user",
              JSON.stringify(user),
            );
          }
        } catch {
          // Local UI copy is non-authoritative.
        }

        setTimeout(() => {
          window.location.href =
            "/dashboard";
        }, 800);
      } catch (
        passwordChangeError
      ) {
        console.error(
          "Password change error:",
          passwordChangeError,
        );

        setError(
          "Unable to connect to the password service. Please try again.",
        );
      } finally {
        setIsSaving(false);
      }
    };

  return (
    <main className="min-h-screen bg-slate-100 flex items-center justify-center px-4">
      <div className="w-full max-w-md bg-white rounded-2xl shadow-xl overflow-hidden">
        <div className="bg-[#17365D] text-white text-center px-8 py-8">
          <div className="text-sm font-semibold tracking-widest mb-3">
            OFFICIAL USE
          </div>

          <h1 className="text-2xl font-bold leading-tight">
            GANESH FESTIVAL
          </h1>

          <h2 className="text-xl font-semibold mt-1">
            BANDOBUST MANAGEMENT SYSTEM
          </h2>

          <p className="text-sm text-blue-100 mt-3">
            Password Security
          </p>
        </div>

        <div className="p-8">
          <h3 className="text-xl font-bold text-slate-800 text-center">
            Change Password
          </h3>

          <p className="text-sm text-slate-500 text-center mt-1 mb-7">
            You must change the default password before continuing.
          </p>

          <label className="block text-sm font-semibold text-slate-700 mb-2">
            Current Password
          </label>

          <input
            type="password"
            value={
              currentPassword
            }
            onChange={(e) =>
              setCurrentPassword(
                e.target.value,
              )
            }
            autoComplete="current-password"
            disabled={isSaving}
            className="w-full border border-slate-300 rounded-lg px-4 py-3 mb-5 outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-slate-100"
          />

          <label className="block text-sm font-semibold text-slate-700 mb-2">
            New Password
          </label>

          <input
            type="password"
            value={newPassword}
            onChange={(e) =>
              setNewPassword(
                e.target.value,
              )
            }
            autoComplete="new-password"
            disabled={isSaving}
            className="w-full border border-slate-300 rounded-lg px-4 py-3 mb-5 outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-slate-100"
          />

          <label className="block text-sm font-semibold text-slate-700 mb-2">
            Confirm New Password
          </label>

          <input
            type="password"
            value={
              confirmPassword
            }
            onChange={(e) =>
              setConfirmPassword(
                e.target.value,
              )
            }
            onKeyDown={(e) => {
              if (
                e.key ===
                "Enter"
              ) {
                void handleChangePassword();
              }
            }}
            autoComplete="new-password"
            disabled={isSaving}
            className="w-full border border-slate-300 rounded-lg px-4 py-3 mb-4 outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-slate-100"
          />

          {error && (
            <div className="bg-red-100 text-red-700 text-sm px-4 py-3 rounded-lg mb-4">
              {error}
            </div>
          )}

          {success && (
            <div className="bg-green-100 text-green-700 text-sm px-4 py-3 rounded-lg mb-4">
              {success}
            </div>
          )}

          <button
            type="button"
            onClick={() => {
              void handleChangePassword();
            }}
            disabled={isSaving}
            className="w-full bg-[#17365D] hover:bg-[#244d7e] disabled:bg-slate-400 disabled:cursor-not-allowed text-white font-semibold py-3 rounded-lg transition"
          >
            {isSaving
              ? "CHANGING PASSWORD..."
              : "CHANGE PASSWORD"}
          </button>

          <p className="text-xs text-slate-400 text-center mt-5">
            Use a password that is different from the default password.
          </p>
        </div>
      </div>
    </main>
  );
}
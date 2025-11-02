import { useEffect, useState } from "react";
import { FiRefreshCw, FiX } from "react-icons/fi";

export default function UpdatePrompt() {
  const [showPrompt, setShowPrompt] = useState(false);
  const [countdown, setCountdown] = useState(30);
  const [isUpdating, setIsUpdating] = useState(false);

  useEffect(() => {
    if ("serviceWorker" in navigator) {
      // Listen for service worker updates
      navigator.serviceWorker.ready.then((registration) => {
        // Check for updates periodically
        const checkForUpdates = () => {
          registration.update();
        };

        // Check every 60 seconds
        const interval = setInterval(checkForUpdates, 60000);

        // Listen for new service worker waiting to activate
        registration.addEventListener("updatefound", () => {
          const newWorker = registration.installing;

          newWorker?.addEventListener("statechange", () => {
            if (
              newWorker.state === "installed" &&
              navigator.serviceWorker.controller
            ) {
              // New service worker is ready
              setShowPrompt(true);
              setCountdown(30); // Reset countdown
            }
          });
        });

        // Also check if there's already a waiting service worker
        if (registration.waiting) {
          setShowPrompt(true);
          setCountdown(30);
        }

        return () => clearInterval(interval);
      });

      // Listen for controller change (new SW activated)
      navigator.serviceWorker.addEventListener("controllerchange", () => {
        window.location.reload();
      });
    }
  }, []);

  // Countdown timer - auto-update after 30 seconds
  useEffect(() => {
    if (!showPrompt || countdown <= 0) return;

    const timer = setTimeout(() => {
      if (countdown === 1) {
        handleUpdate();
      } else {
        setCountdown(countdown - 1);
      }
    }, 1000);

    return () => clearTimeout(timer);
  }, [showPrompt, countdown]);

  const handleUpdate = async () => {
    setIsUpdating(true);

    if ("serviceWorker" in navigator) {
      const registration = await navigator.serviceWorker.ready;

      if (registration.waiting) {
        // Tell waiting service worker to skip waiting and activate
        registration.waiting.postMessage({ type: "SKIP_WAITING" });
      } else {
        // No waiting worker, just reload
        window.location.reload();
      }
    }
  };

  const handleDismiss = () => {
    setShowPrompt(false);
    setCountdown(30);
  };

  if (!showPrompt) return null;

  return (
    <div className="fixed top-4 left-4 right-4 md:left-auto md:right-4 md:max-w-md z-50 animate-slide-down">
      <div className="bg-linear-to-br from-green-600 to-green-700 text-white rounded-xl shadow-2xl p-4">
        <div className="flex items-start gap-3">
          <div className="shrink-0 mt-1">
            <FiRefreshCw
              className={`text-2xl ${isUpdating ? "animate-spin" : ""}`}
            />
          </div>
          <div className="flex-1">
            <h3 className="font-semibold text-lg mb-1">Update Available</h3>
            <p className="text-sm text-green-100 mb-3">
              A new version of the app is available. Update now to get the
              latest features and improvements.
            </p>
            <div className="flex items-center gap-2 mb-3">
              <div className="text-xs text-green-100">
                Auto-updating in {countdown}s...
              </div>
              <div className="flex-1 bg-green-800 rounded-full h-1">
                <div
                  className="bg-white h-1 rounded-full transition-all duration-1000"
                  style={{ width: `${(countdown / 30) * 100}%` }}
                />
              </div>
            </div>
            <div className="flex gap-2">
              <button
                onClick={handleUpdate}
                disabled={isUpdating}
                className="btn btn-sm bg-white text-green-600 hover:bg-green-50 border-0 disabled:bg-gray-200"
              >
                {isUpdating ? (
                  <>
                    <span className="loading loading-spinner loading-xs" />
                    Updating...
                  </>
                ) : (
                  "Update Now"
                )}
              </button>
              <button
                onClick={handleDismiss}
                disabled={isUpdating}
                className="btn btn-sm btn-ghost hover:bg-green-600 disabled:opacity-50"
              >
                Later
              </button>
            </div>
          </div>
          <button
            onClick={handleDismiss}
            disabled={isUpdating}
            className="shrink-0 p-1 hover:bg-green-600 rounded-lg transition-colors disabled:opacity-50"
            aria-label="Close"
          >
            <FiX className="text-xl" />
          </button>
        </div>
      </div>
    </div>
  );
}

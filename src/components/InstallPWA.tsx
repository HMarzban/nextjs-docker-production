import { useEffect, useState } from "react";
import { FiDownload, FiX } from "react-icons/fi";

interface BeforeInstallPromptEvent extends Event {
  prompt: () => Promise<void>;
  userChoice: Promise<{ outcome: "accepted" | "dismissed" }>;
}

export default function InstallPWA() {
  const [deferredPrompt, setDeferredPrompt] =
    useState<BeforeInstallPromptEvent | null>(null);
  const [showInstallPrompt, setShowInstallPrompt] = useState(false);

  useEffect(() => {
    const handler = (e: Event) => {
      e.preventDefault();
      setDeferredPrompt(e as BeforeInstallPromptEvent);
      setShowInstallPrompt(true);
    };

    window.addEventListener("beforeinstallprompt", handler);

    // Check if already installed
    if (window.matchMedia("(display-mode: standalone)").matches) {
      setShowInstallPrompt(false);
    }

    return () => window.removeEventListener("beforeinstallprompt", handler);
  }, []);

  const handleInstall = async () => {
    if (!deferredPrompt) return;

    deferredPrompt.prompt();
    const { outcome } = await deferredPrompt.userChoice;

    if (outcome === "accepted") {
      setDeferredPrompt(null);
      setShowInstallPrompt(false);
    }
  };

  const handleDismiss = () => {
    setShowInstallPrompt(false);
    // Don't show again for this session
    sessionStorage.setItem("pwa-prompt-dismissed", "true");
  };

  // Don't show if already dismissed this session
  useEffect(() => {
    if (sessionStorage.getItem("pwa-prompt-dismissed")) {
      setShowInstallPrompt(false);
    }
  }, []);

  if (!showInstallPrompt) return null;

  return (
    <div className="fixed bottom-4 left-4 right-4 md:left-auto md:right-4 md:max-w-sm z-50 animate-slide-up">
      <div className="bg-linear-to-br from-blue-600 to-blue-700 text-white rounded-xl shadow-2xl p-4">
        <div className="flex items-start gap-3">
          <div className="shrink-0 mt-1">
            <FiDownload className="text-2xl" />
          </div>
          <div className="flex-1">
            <h3 className="font-semibold text-lg mb-1">Install App</h3>
            <p className="text-sm text-blue-100 mb-3">
              Install this app on your device for quick access and offline use.
            </p>
            <div className="flex gap-2">
              <button
                onClick={handleInstall}
                className="btn btn-sm bg-white text-blue-600 hover:bg-blue-50 border-0"
              >
                Install
              </button>
              <button
                onClick={handleDismiss}
                className="btn btn-sm btn-ghost hover:bg-blue-600"
              >
                Not now
              </button>
            </div>
          </div>
          <button
            onClick={handleDismiss}
            className="shrink-0 p-1 hover:bg-blue-600 rounded-lg transition-colors"
            aria-label="Close"
          >
            <FiX className="text-xl" />
          </button>
        </div>
      </div>
    </div>
  );
}

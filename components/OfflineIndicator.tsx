import { useEffect, useState } from "react";
import { FiWifiOff, FiWifi } from "react-icons/fi";

export default function OfflineIndicator() {
  const [isOnline, setIsOnline] = useState(true);
  const [showNotification, setShowNotification] = useState(false);

  useEffect(() => {
    setIsOnline(navigator.onLine);

    const handleOnline = () => {
      setIsOnline(true);
      setShowNotification(true);
      setTimeout(() => setShowNotification(false), 3000);
    };

    const handleOffline = () => {
      setIsOnline(false);
      setShowNotification(true);
    };

    window.addEventListener("online", handleOnline);
    window.addEventListener("offline", handleOffline);

    return () => {
      window.removeEventListener("online", handleOnline);
      window.removeEventListener("offline", handleOffline);
    };
  }, []);

  if (!showNotification && isOnline) return null;

  return (
    <div
      className={`fixed top-4 right-4 z-50 flex items-center gap-2 px-4 py-3 rounded-lg shadow-lg transition-all duration-300 ${
        isOnline
          ? "bg-green-600 text-white"
          : "bg-red-600 text-white animate-pulse"
      }`}
    >
      {isOnline ? (
        <>
          <FiWifi className="text-xl" />
          <span className="font-medium">Back online</span>
        </>
      ) : (
        <>
          <FiWifiOff className="text-xl" />
          <span className="font-medium">Offline mode</span>
        </>
      )}
    </div>
  );
}

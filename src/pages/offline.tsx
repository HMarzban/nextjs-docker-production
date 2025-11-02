import Head from "next/head";
import Link from "next/link";
import { FiWifiOff, FiRefreshCw } from "react-icons/fi";

export default function Offline() {
  const handleRetry = () => {
    window.location.reload();
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-linear-to-br from-gray-900 via-gray-800 to-black text-white p-4">
      <Head>
        <title>Offline - Next.js Docker App</title>
      </Head>

      <div className="text-center max-w-md">
        <div className="mb-6 inline-block p-6 bg-red-900/30 rounded-full">
          <FiWifiOff className="text-6xl text-red-400" />
        </div>

        <h1 className="text-4xl font-bold mb-4">You&apos;re Offline</h1>

        <p className="text-gray-400 mb-8">
          It looks like you&apos;ve lost your internet connection. Some features
          may not be available until you&apos;re back online.
        </p>

        <div className="flex flex-col gap-3">
          <button onClick={handleRetry} className="btn btn-primary gap-2">
            <FiRefreshCw />
            Try Again
          </button>

          <Link href="/" className="btn btn-ghost">
            Go Home
          </Link>
        </div>
      </div>
    </div>
  );
}

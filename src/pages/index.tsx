import Head from "next/head";
import Link from "next/link";
import Image from "next/image";

export default function Home() {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-linear-to-br from-gray-900 via-gray-800 to-black text-white">
      <Head>
        <title>Next.js on Docker</title>
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <main className="flex-1 flex flex-col items-center justify-center px-4 py-12 w-full max-w-6xl">
        <h1 className="text-5xl md:text-6xl font-bold text-center mb-4">
          Welcome to{" "}
          <a
            href="https://nextjs.org"
            className="text-blue-500 hover:text-blue-400 transition-colors"
          >
            Next.js
          </a>
        </h1>

        <p className="text-xl text-gray-400 mb-12 text-center">
          Production-ready app with TypeScript, Tailwind v4 & daisyUI
        </p>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 w-full max-w-4xl mb-8">
          <Link
            href="/weather"
            className="p-6 border-2 border-blue-500 rounded-xl hover:border-blue-400 transition-colors bg-blue-900/30 backdrop-blur"
          >
            <h3 className="text-2xl font-semibold mb-2">
              🌤️ Weather Dashboard
            </h3>
            <p className="text-gray-400">
              Check real-time weather for cities around the world
            </p>
          </Link>

          <a
            href="https://nextjs.org/docs"
            className="p-6 border border-gray-700 rounded-xl hover:border-blue-500 transition-colors bg-gray-900/50 backdrop-blur"
          >
            <h3 className="text-2xl font-semibold mb-2">
              Documentation &rarr;
            </h3>
            <p className="text-gray-400">
              Find in-depth information about Next.js features and API.
            </p>
          </a>

          <a
            href="https://daisyui.com"
            target="_blank"
            rel="noopener noreferrer"
            className="p-6 border border-gray-700 rounded-xl hover:border-blue-500 transition-colors bg-gray-900/50 backdrop-blur"
          >
            <h3 className="text-2xl font-semibold mb-2">daisyUI &rarr;</h3>
            <p className="text-gray-400">
              Beautiful Tailwind CSS components library we&apos;re using
            </p>
          </a>

          <a
            href="https://github.com/vercel/next.js/tree/canary/examples"
            className="p-6 border border-gray-700 rounded-xl hover:border-blue-500 transition-colors bg-gray-900/50 backdrop-blur"
          >
            <h3 className="text-2xl font-semibold mb-2">Examples &rarr;</h3>
            <p className="text-gray-400">
              Discover and deploy boilerplate example Next.js projects.
            </p>
          </a>
        </div>

        <div className="flex flex-wrap gap-3 justify-center">
          <div className="badge badge-primary gap-2">TypeScript</div>
          <div className="badge badge-secondary gap-2">Tailwind v4</div>
          <div className="badge badge-accent gap-2">daisyUI</div>
          <div className="badge badge-info gap-2">Docker</div>
        </div>
      </main>

      <footer className="w-full py-8 border-t border-gray-800 flex justify-center items-center">
        <a
          href="https://vercel.com"
          target="_blank"
          rel="noopener noreferrer"
          className="flex items-center gap-2 text-gray-400 hover:text-white transition-colors"
        >
          Powered by{" "}
          <Image
            src="/vercel.svg"
            alt="Vercel Logo"
            width={16}
            height={16}
            className="h-4"
          />{" "}
          1.2.0
        </a>
      </footer>
    </div>
  );
}

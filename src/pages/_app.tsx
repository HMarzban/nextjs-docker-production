import type { AppProps } from "next/app";
import Head from "next/head";
import "@/styles/globals.css";
import OfflineIndicator from "@/components/OfflineIndicator";
import InstallPWA from "@/components/InstallPWA";
import UpdatePrompt from "@/components/UpdatePrompt";

export default function MyApp({ Component, pageProps }: AppProps) {
  // Service worker is auto-registered by @ducanh2912/next-pwa

  return (
    <>
      <Head>
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta
          name="description"
          content="Next.js with Docker and Bun - A production-ready PWA"
        />
        <meta name="theme-color" content="#3b82f6" />

        {/* PWA Meta Tags */}
        <meta name="application-name" content="Next Docker" />
        <meta name="apple-mobile-web-app-capable" content="yes" />
        <meta
          name="apple-mobile-web-app-status-bar-style"
          content="black-translucent"
        />
        <meta name="apple-mobile-web-app-title" content="Next Docker" />
        <meta name="format-detection" content="telephone=no" />
        <meta name="mobile-web-app-capable" content="yes" />

        {/* Manifest */}
        <link rel="manifest" href="/manifest.json" />

        {/* Icons */}
        <link rel="icon" href="/favicon.ico" />
        <link rel="apple-touch-icon" href="/icon-192.png" />
      </Head>

      <Component {...pageProps} />
      <UpdatePrompt />
      <OfflineIndicator />
      <InstallPWA />
    </>
  );
}

import type { AppProps } from "next/app";
import Head from "next/head";
import "../styles/globals.css";

export default function MyApp({ Component, pageProps }: AppProps) {
  return (
    <>
      <Head>
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="description" content="Next.js with Docker and Bun" />
        <meta name="theme-color" content="#3b82f6" />
      </Head>
      <Component {...pageProps} />
    </>
  );
}

import Head from "next/head";
import "@fontsource/poppins/400.css";
import "@fontsource/poppins/700.css";

import { ConnectButton } from "@rainbow-me/rainbowkit";
import { GetGreeter, SetGreeter } from "../components/contract";

export default function Home() {
  return (
    <div className={""}>
      <Head>
        <title>Balls of Art</title>
        <meta name="description" content="Great Balls of Art" />
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <header style={{ padding: "1rem" }}>
        <ConnectButton />
      </header>

      <main
        style={{
          minHeight: "60vh",
          flex: "1",
          display: "flex",
          flexDirection: "column",
          justifyContent: "center",
          alignItems: "center"
        }}
      >
        <GetGreeter />
        <SetGreeter />
      </main>
    </div>
  );
}

import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata = {
  title: "LendX - Decentralized Cross-Chain Lending Platform",
  description:
    "A decentralized, cross-chain lending platform built on the Sui blockchain ecosystem that enables users to access stablecoins without selling their crypto holdings.",
  keywords:
    "LendX, DeFi, Lending, Stablecoins, Crypto, Blockchain, Sui, Cross-Chain, Decentralized Finance",
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased`}
      >
        {children}
      </body>
    </html>
  );
}

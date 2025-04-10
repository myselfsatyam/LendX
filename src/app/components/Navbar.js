"use client";

import { useState, useEffect } from "react";
import { motion } from "framer-motion";
import Link from "next/link";
import { FaWallet, FaLeaf } from "react-icons/fa";

const Navbar = () => {
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      const isScrolled = window.scrollY > 10;
      if (isScrolled !== scrolled) {
        setScrolled(isScrolled);
      }
    };

    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, [scrolled]);

  return (
    <motion.nav
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
        scrolled ? "glass-effect py-3 border-b border-primary/10" : "py-5"
      }`}
      initial={{ opacity: 0, y: -20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5 }}
    >
      <div className="container mx-auto px-4 flex justify-between items-center">
        <Link href="/" className="flex items-center space-x-2">
          <div className="relative">
            <motion.div
              animate={{ rotate: [0, 10, 0] }}
              transition={{ duration: 4, repeat: Infinity, ease: "easeInOut" }}
              className="absolute -left-6 top-0 text-primary opacity-80"
            >
              <FaLeaf />
            </motion.div>
            <span className="text-2xl font-bold gradient-text">LendX</span>
          </div>
        </Link>

        <div className="hidden md:flex space-x-8">
          {[
            { href: "#features", label: "Features" },
            { href: "#how-it-works", label: "How It Works" },
            { href: "#use-cases", label: "Use Cases" },
            { href: "#technology", label: "Technology" },
          ].map((item, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.1 * index, duration: 0.5 }}
            >
              <Link
                href={item.href}
                className="text-white hover:text-secondary transition-colors relative group"
              >
                {item.label}
                <span className="absolute -bottom-1 left-0 w-0 h-0.5 bg-gradient-to-r from-primary to-secondary group-hover:w-full transition-all duration-300"></span>
              </Link>
            </motion.div>
          ))}
        </div>

        <motion.button
          className="px-4 py-2 flex items-center space-x-2 relative overflow-hidden rounded-lg card-3d"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.5 }}
          whileHover={{ scale: 1.05 }}
          whileTap={{ scale: 0.95 }}
        >
          {/* Animated gradient background */}
          <div className="absolute inset-0 bg-gradient-to-r from-primary to-secondary opacity-80"></div>

          {/* Shine effect */}
          <motion.div
            className="absolute inset-0 opacity-60"
            initial={{ x: "-100%" }}
            animate={{ x: "200%" }}
            transition={{ repeat: Infinity, duration: 1.5, repeatDelay: 0.5 }}
            style={{
              background:
                "linear-gradient(90deg, transparent, rgba(255,255,255,0.3), transparent)",
            }}
          />

          <FaWallet className="relative z-10 text-white" />
          <span className="relative z-10 text-white font-medium">
            Connect Wallet
          </span>
        </motion.button>
      </div>
    </motion.nav>
  );
};

export default Navbar;

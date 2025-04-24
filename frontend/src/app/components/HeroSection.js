"use client";

import { useEffect, useRef } from "react";
import { motion } from "framer-motion";
import { FaArrowRight } from "react-icons/fa";

const EcoParticles = () => {
  // Generate 20 random particles
  const particles = Array.from({ length: 20 }).map((_, i) => ({
    id: i,
    size: Math.random() * 6 + 3, // Slightly smaller particles
    left: `${Math.random() * 100}%`,
    delay: Math.random() * 20,
    duration: Math.random() * 15 + 15,
  }));

  return (
    <div className="eco-particles">
      {particles.map((particle) => (
        <div
          key={particle.id}
          className="eco-particle"
          style={{
            width: `${particle.size}px`,
            height: `${particle.size}px`,
            left: particle.left,
            animationDelay: `${particle.delay}s`,
            animationDuration: `${particle.duration}s`,
            opacity: "0.15", // Lower opacity for particles
          }}
        />
      ))}
    </div>
  );
};

const Sphere3D = () => {
  return (
    <div className="relative w-full h-full">
      <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-40 h-40 md:w-56 md:h-56">
        {/* Reduced size and opacity of all elements */}
        <div className="absolute inset-0 rounded-full bg-gradient-to-br from-primary to-secondary opacity-40 blur-md"></div>
        <div className="absolute inset-0 rounded-full bg-gradient-to-br from-primary/50 to-secondary/50 backdrop-blur-sm"></div>
        <div className="absolute inset-4 rounded-full bg-gradient-to-br from-primary/20 to-secondary/20 backdrop-blur-sm"></div>
        <div className="absolute inset-0 rounded-full bg-primary/5 backdrop-blur-2xl border border-primary/10"></div>
        <div className="absolute inset-0 rounded-full bg-gradient-to-br from-transparent to-primary/20 mix-blend-overlay"></div>

        {/* 3D effect rings - more subtle */}
        <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-full h-full border border-secondary/10 rounded-full"></div>
        <div
          className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-[110%] h-[110%] border border-primary/20 rounded-full animate-spin"
          style={{ animationDuration: "30s" }}
        ></div>
        <div
          className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-[120%] h-[120%] border border-accent/5 rounded-full animate-spin"
          style={{ animationDuration: "25s", animationDirection: "reverse" }}
        ></div>
      </div>
    </div>
  );
};

const HeroSection = () => {
  return (
    <section className="relative min-h-screen flex items-center pt-20 overflow-hidden bg-background">
      <EcoParticles />

      {/* Background gradient animation - more subtle */}
      <div className="absolute inset-0 z-0">
        {/* Reduced size and opacity of background blurs */}
        <div className="absolute top-0 -left-40 w-80 h-80 bg-primary opacity-5 rounded-full filter blur-3xl" />
        <div className="absolute bottom-0 -right-40 w-80 h-80 bg-secondary opacity-5 rounded-full filter blur-3xl" />
        
        {/* Additional darker overlay to tone down brightness */}
        <div className="absolute inset-0 bg-background/40"></div>
      </div>

      <div className="container mx-auto px-4 z-10 mt-12">
        <div className="grid md:grid-cols-2 gap-12 items-center">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
          >
            <h1 className="text-4xl md:text-6xl font-bold mb-4">
              <span className="gradient-text">Decentralized</span> Cross-Chain
              Lending Platform
            </h1>

            <p className="text-lg md:text-xl text-muted mb-8 max-w-lg">
              Access stablecoins without selling your crypto holdings. Preserve
              your long-term asset positions and avoid triggering taxable
              events.
            </p>

            <div className="flex flex-col sm:flex-row gap-4">
              <motion.button
                className="px-6 py-3 bg-primary rounded-lg text-white font-medium flex items-center justify-center gap-2 hover:bg-opacity-90 transition-all"
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
              >
                Launch App <FaArrowRight />
              </motion.button>

              <motion.button
                className="px-6 py-3 gradient-border bg-card hover:bg-opacity-90 transition-all"
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
              >
                Learn More
              </motion.button>
            </div>

            <div className="grid grid-cols-3 gap-6 mt-16">
              <motion.div
                className="text-center card-3d"
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.3, duration: 0.5 }}
              >
                <h3 className="text-2xl md:text-3xl font-bold gradient-text">
                  Fast
                </h3>
                <p className="text-muted">Instant transactions</p>
              </motion.div>

              <motion.div
                className="text-center card-3d"
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.4, duration: 0.5 }}
              >
                <h3 className="text-2xl md:text-3xl font-bold gradient-text">
                  Secure
                </h3>
                <p className="text-muted">Built on Sui blockchain</p>
              </motion.div>

              <motion.div
                className="text-center card-3d"
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.5, duration: 0.5 }}
              >
                <h3 className="text-2xl md:text-3xl font-bold gradient-text">
                  Efficient
                </h3>
                <p className="text-muted">Low fees & high yields</p>
              </motion.div>
            </div>
          </motion.div>

          <motion.div
            className="relative"
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.6, delay: 0.2 }}
          >
            <div className="relative glass-effect rounded-2xl p-6 glow card-3d">
              <div className="absolute -top-10 -right-10 w-16 h-16 bg-secondary opacity-10 rounded-full filter blur-xl"></div>
              <div className="absolute -bottom-5 -left-5 w-14 h-14 bg-primary opacity-10 rounded-full filter blur-xl"></div>

              <div className="mb-8 relative"> {/* Reduced space for sphere */}
                <div className="absolute inset-0 -z-10">
                  <Sphere3D />
                </div>
              </div>

              <div className="glass-effect rounded-xl p-6 mb-5 relative backdrop-blur-md">
                <h3 className="text-xl font-medium mb-3">Total Value Locked</h3>
                <p className="text-3xl font-bold gradient-text">$24.7M</p>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <motion.div
                  className="glass-effect rounded-xl p-4 floating"
                  style={{ animationDelay: "0s", animationDuration: "8s" }}
                >
                  <h4 className="text-sm text-muted mb-1">Borrowers</h4>
                  <p className="text-xl font-bold">12,450+</p>
                </motion.div>

                <motion.div
                  className="glass-effect rounded-xl p-4 floating"
                  style={{ animationDelay: "1s", animationDuration: "7s" }}
                >
                  <h4 className="text-sm text-muted mb-1">
                    Liquidity Providers
                  </h4>
                  <p className="text-xl font-bold">3,275+</p>
                </motion.div>

                <motion.div
                  className="glass-effect rounded-xl p-4 floating"
                  style={{ animationDelay: "1.5s", animationDuration: "9s" }}
                >
                  <h4 className="text-sm text-muted mb-1">Chains Supported</h4>
                  <p className="text-xl font-bold">8+</p>
                </motion.div>

                <motion.div
                  className="glass-effect rounded-xl p-4 floating"
                  style={{ animationDelay: "0.5s", animationDuration: "8.5s" }}
                >
                  <h4 className="text-sm text-muted mb-1">Avg. APY</h4>
                  <p className="text-xl font-bold gradient-text">4.6%</p>
                </motion.div>
              </div>
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  );
};

export default HeroSection;

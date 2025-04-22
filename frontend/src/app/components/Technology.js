"use client";

import { useRef, useState } from "react";
import { motion, useInView, useMotionValue, useTransform } from "framer-motion";
import Image from "next/image";

// 3D Tech Card component with hover effect
const TechCard = ({ name, description, isInView, delay }) => {
  const x = useMotionValue(0);
  const y = useMotionValue(0);
  const rotateX = useTransform(y, [-100, 100], [30, -30]);
  const rotateY = useTransform(x, [-100, 100], [-30, 30]);

  function handleMouse(event) {
    const rect = event.currentTarget.getBoundingClientRect();
    const width = rect.width;
    const height = rect.height;
    const mouseX = event.clientX - rect.left;
    const mouseY = event.clientY - rect.top;
    const xPct = mouseX / width - 0.5;
    const yPct = mouseY / height - 0.5;
    x.set(xPct * 100);
    y.set(yPct * 100);
  }

  function handleMouseLeave() {
    x.set(0);
    y.set(0);
  }

  return (
    <motion.div
      className="glass-effect rounded-xl h-full"
      style={{
        transformStyle: "preserve-3d",
        transform: "perspective(1000px)",
        rotateX,
        rotateY,
        transition: "transform 0.1s ease",
      }}
      onMouseMove={handleMouse}
      onMouseLeave={handleMouseLeave}
      initial={{ opacity: 0, y: 20 }}
      animate={isInView ? { opacity: 1, y: 0 } : { opacity: 0, y: 20 }}
      transition={{ duration: 0.5, delay }}
    >
      <div
        className="relative p-6 z-10 h-full"
        style={{ transform: "translateZ(20px)" }}
      >
        {/* Glowing orb in the corner */}
        <div className="absolute -top-3 -right-3 w-12 h-12 rounded-full bg-gradient-to-br from-primary to-secondary opacity-80 blur-md"></div>

        <h3 className="text-xl font-bold mb-3 gradient-text">{name}</h3>
        <p className="text-muted">{description}</p>

        {/* Shine effect */}
        <div
          className="absolute inset-0 opacity-30 rounded-xl"
          style={{
            background:
              "linear-gradient(105deg, transparent, rgba(255,255,255,0.2) 25%, transparent 50%)",
            transform: "translateZ(5px)",
          }}
        ></div>
      </div>
    </motion.div>
  );
};

// 3D Hexagon Grid Animation
const HexagonGrid = () => {
  return (
    <div className="relative w-full h-full">
      <div className="absolute inset-0 flex items-center justify-center">
        <div className="grid grid-cols-4 gap-4 transform rotate-12 scale-125">
          {Array.from({ length: 16 }).map((_, i) => (
            <motion.div
              key={i}
              className="w-8 h-8 bg-gradient-to-br from-primary/20 to-secondary/20 backdrop-blur-sm rounded-lg"
              initial={{ opacity: 0, scale: 0.5 }}
              animate={{
                opacity: [0.2, 0.5, 0.2],
                scale: [0.8, 1, 0.8],
                rotateZ: [0, 180, 0],
              }}
              transition={{
                duration: Math.random() * 3 + 2,
                repeat: Infinity,
                delay: Math.random() * 2,
              }}
            />
          ))}
        </div>
      </div>
    </div>
  );
};

const Technology = () => {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true, margin: "-100px" });

  const technologies = [
    {
      name: "Sui Blockchain",
      description:
        "High-performance blockchain platform with parallel execution for fast and low-cost transactions.",
      delay: 0.1,
    },
    {
      name: "Pyth Network",
      description:
        "Real-time price feeds for accurate collateral valuation and risk management.",
      delay: 0.2,
    },
    {
      name: "Wormhole",
      description:
        "Cross-chain messaging protocol enabling seamless asset transfers between blockchains.",
      delay: 0.3,
    },
    {
      name: "Walrus",
      description:
        "Secure on-chain storage solution for reliable and immutable data management.",
      delay: 0.4,
    },
  ];

  // Interactive security features
  const [activeFeature, setActiveFeature] = useState(0);
  const securityFeatures = [
    "Real-time collateral monitoring via Pyth Network",
    "Automated liquidation triggers",
    "Secure cross-chain asset management through Wormhole",
    "Immutable on-chain storage with Walrus",
    "Regular security audits and compliance checks",
  ];

  return (
    <section id="technology" className="py-20 relative overflow-hidden">
      {/* Animated background */}
      <div className="absolute inset-0 z-0 gradient-bg"></div>

      {/* Eco particles */}
      <div className="eco-particles">
        {Array.from({ length: 15 }).map((_, i) => (
          <div
            key={i}
            className="eco-particle"
            style={{
              width: `${Math.random() * 8 + 4}px`,
              height: `${Math.random() * 8 + 4}px`,
              left: `${Math.random() * 100}%`,
              animationDelay: `${Math.random() * 20}s`,
              animationDuration: `${Math.random() * 15 + 15}s`,
            }}
          />
        ))}
      </div>

      <div className="container mx-auto px-4 relative z-10" ref={ref}>
        <motion.div
          className="text-center mb-16"
          initial={{ opacity: 0, y: 20 }}
          animate={isInView ? { opacity: 1, y: 0 } : { opacity: 0, y: 20 }}
          transition={{ duration: 0.5 }}
        >
          <h2 className="text-3xl md:text-5xl font-bold mb-4">
            Powered by{" "}
            <span className="gradient-text">Advanced Technology</span>
          </h2>
          <p className="text-muted max-w-2xl mx-auto">
            LendX leverages cutting-edge blockchain technology to provide a
            secure, efficient, and scalable lending platform.
          </p>
        </motion.div>

        <div className="grid md:grid-cols-2 gap-8">
          {technologies.map((tech, index) => (
            <TechCard
              key={index}
              name={tech.name}
              description={tech.description}
              isInView={isInView}
              delay={tech.delay}
            />
          ))}
        </div>

        <motion.div
          className="mt-20 glass-effect rounded-xl p-8 card-3d"
          initial={{ opacity: 0, y: 20 }}
          animate={isInView ? { opacity: 1, y: 0 } : { opacity: 0, y: 20 }}
          transition={{ duration: 0.5, delay: 0.5 }}
          whileHover={{ translateY: -5 }}
        >
          <div className="grid md:grid-cols-2 gap-8 items-center">
            <div>
              <h3 className="text-2xl font-bold mb-6 gradient-text">
                Security & Risk Management
              </h3>
              <ul className="space-y-4">
                {securityFeatures.map((feature, index) => (
                  <motion.li
                    key={index}
                    className={`flex items-start gap-3 p-2 rounded-lg transition-all ${
                      activeFeature === index ? "bg-primary/10" : ""
                    }`}
                    whileHover={{ x: 5 }}
                    onClick={() => setActiveFeature(index)}
                  >
                    <span className="text-secondary mt-1 text-xl">✓</span>
                    <span>{feature}</span>
                  </motion.li>
                ))}
              </ul>
            </div>

            <div className="relative h-64 rounded-xl overflow-hidden glow">
              <HexagonGrid />
              <div className="absolute inset-0 bg-gradient-to-br from-primary/10 to-secondary/10 z-10"></div>
              <div className="absolute inset-0 flex items-center justify-center">
                <div
                  className="text-center z-20 floating"
                  style={{ animationDuration: "8s" }}
                >
                  <div className="w-24 h-24 rounded-full bg-card mx-auto flex items-center justify-center mb-4 border border-secondary/30 glow">
                    <span className="text-4xl">🔒</span>
                  </div>
                  <h4 className="text-xl font-bold gradient-text">
                    Enterprise-Grade Security
                  </h4>
                </div>
              </div>
            </div>
          </div>
        </motion.div>
      </div>
    </section>
  );
};

export default Technology;

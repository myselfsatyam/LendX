"use client";

import { useRef } from "react";
import { motion, useInView } from "framer-motion";
import {
  FaChartLine,
  FaShieldAlt,
  FaMoneyBillWave,
  FaGlobe,
  FaRocket,
} from "react-icons/fa";

// 3D Leaf component for decorative elements
const Leaf3D = ({ size = 30, rotate = 0, top, left, delay = 0 }) => {
  return (
    <motion.div
      className="absolute"
      style={{ top, left, width: size, height: size }}
      initial={{ opacity: 0, rotate: rotate, scale: 0.5 }}
      animate={{ opacity: 1, rotate: rotate, scale: 1 }}
      transition={{ delay, duration: 0.8, type: "spring" }}
    >
      <div 
        className="w-full h-full opacity-30" 
        style={{ 
          background: `radial-gradient(ellipse at center, var(--primary) 0%, transparent 70%)`,
          transform: `rotate(${rotate}deg)`
        }}
      >
        <div className="absolute inset-0 flex items-center justify-center text-white" style={{ transform: `rotate(${-rotate}deg)` }}>
          🌱
        </div>
      </div>
    </motion.div>
  );
};

const FeatureCard = ({ icon, title, description, delay }) => {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true, margin: "-100px" });

  return (
    <motion.div
      ref={ref}
      className="glass-effect rounded-xl p-6 h-full card-3d relative overflow-hidden"
      initial={{ opacity: 0, y: 20 }}
      animate={isInView ? { opacity: 1, y: 0 } : { opacity: 0, y: 20 }}
      transition={{ duration: 0.5, delay }}
      whileHover={{ translateY: -10 }}
    >
      <div className="absolute inset-0 bg-gradient-to-br from-primary/5 to-secondary/5 z-0"></div>
      <div className="relative z-10">
        <div className="w-14 h-14 rounded-full bg-gradient-to-br from-primary to-primary/50 flex items-center justify-center mb-4 text-xl text-white shadow-lg">
          {icon}
        </div>
        <h3 className="text-xl font-bold mb-3 gradient-text">{title}</h3>
        <p className="text-muted">{description}</p>
      </div>
    </motion.div>
  );
};

const Features = () => {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true, margin: "-100px" });

  const features = [
    {
      icon: <FaGlobe className="text-white" />,
      title: "Cross-Chain Lending",
      description:
        "Access liquidity across multiple blockchain networks with seamless interoperability.",
      delay: 0.1,
    },
    {
      icon: <FaChartLine className="text-white" />,
      title: "Asset Preservation",
      description:
        "Maintain your crypto exposure while accessing stablecoins for other investments or expenses.",
      delay: 0.2,
    },
    {
      icon: <FaShieldAlt className="text-white" />,
      title: "Real-Time Risk Management",
      description:
        "Dynamic pricing and collateral monitoring with automated risk assessment.",
      delay: 0.3,
    },
    {
      icon: <FaMoneyBillWave className="text-white" />,
      title: "Tax Efficiency",
      description:
        "Avoid triggering taxable events by borrowing against your assets instead of selling them.",
      delay: 0.4,
    },
    {
      icon: <FaRocket className="text-white" />,
      title: "High Performance",
      description:
        "Built on Sui blockchain for fast, secure, and low-cost operations with minimal latency.",
      delay: 0.5,
    },
  ];

  // Decorative elements
  const decorativeLeaves = [
    { size: 50, rotate: 15, top: "10%", left: "5%", delay: 0.1 },
    { size: 30, rotate: -10, top: "65%", left: "15%", delay: 0.3 },
    { size: 40, rotate: 25, top: "20%", left: "85%", delay: 0.5 },
    { size: 35, rotate: -20, top: "70%", left: "90%", delay: 0.2 },
  ];

  return (
    <section id="features" className="py-20 relative overflow-hidden">
      <div className="absolute inset-0 z-0 bg-gradient-to-b from-background to-card/30"></div>
      <div className="absolute inset-0 z-0">
        <div className="absolute top-1/4 -right-20 w-80 h-80 bg-primary opacity-5 rounded-full filter blur-3xl" />
      </div>
      
      {/* Decorative leaves */}
      {decorativeLeaves.map((leaf, index) => (
        <Leaf3D key={index} {...leaf} />
      ))}

      <div className="container mx-auto px-4 relative z-10">
        <motion.div
          ref={ref}
          className="text-center mb-16"
          initial={{ opacity: 0, y: 20 }}
          animate={isInView ? { opacity: 1, y: 0 } : { opacity: 0, y: 20 }}
          transition={{ duration: 0.5 }}
        >
          <h2 className="text-3xl md:text-5xl font-bold mb-4">
            Powerful <span className="gradient-text">Features</span>
          </h2>
          <p className="text-muted max-w-2xl mx-auto">
            LendX combines cutting-edge technology with user-focused design to
            deliver a seamless lending experience across multiple blockchains.
          </p>
        </motion.div>

        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
          {features.map((feature, index) => (
            <FeatureCard key={index} {...feature} />
          ))}
        </div>

        {/* 3D Coin Animation */}
        <motion.div
          className="mt-20 text-center"
          initial={{ opacity: 0 }}
          animate={isInView ? { opacity: 1 } : { opacity: 0 }}
          transition={{ duration: 0.8, delay: 0.6 }}
        >
          <div className="inline-block relative">
            <div className="w-24 h-24 mx-auto relative floating" style={{ perspective: "1000px" }}>
              <div className="absolute inset-0 rounded-full bg-gradient-to-r from-primary to-secondary shadow-lg transform rotate-45"></div>
              <div className="absolute inset-2 rounded-full bg-card flex items-center justify-center">
                <span className="text-2xl font-bold gradient-text">$</span>
              </div>
            </div>
            <div className="mt-6 text-lg font-medium text-center">
              <span className="gradient-text">Start earning with LendX today</span>
            </div>
          </div>
        </motion.div>
      </div>
    </section>
  );
};

export default Features;

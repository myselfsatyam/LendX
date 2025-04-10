"use client";

import { useRef } from "react";
import { motion, useInView } from "framer-motion";
import { FaLink, FaLock, FaCoins, FaExchangeAlt } from "react-icons/fa";

// 3D Node Connect Line animation
const ConnectionLine = ({ isInView, number }) => {
  return (
    <motion.div
      className="absolute top-1/2 left-[7%] w-[110%] h-4 z-0"
      initial={{ opacity: 0 }}
      animate={isInView ? { opacity: 1 } : { opacity: 0 }}
      transition={{ duration: 0.8, delay: number * 0.2 }}
    >
      <motion.div
        className="h-[2px] bg-gradient-to-r from-primary via-secondary to-transparent relative overflow-visible"
        initial={{ scaleX: 0, originX: 0 }}
        animate={isInView ? { scaleX: 1 } : { scaleX: 0 }}
        transition={{ duration: 1.2, delay: number * 0.2 }}
      >
        {/* Animated particle along the line */}
        <motion.div
          className="absolute top-1/2 -translate-y-1/2 w-3 h-3 rounded-full bg-secondary"
          initial={{ left: "0%", opacity: 0 }}
          animate={{
            left: ["0%", "100%"],
            opacity: [0, 1, 0],
          }}
          transition={{
            duration: 3,
            delay: number * 0.2 + 1,
            repeat: Infinity,
            repeatDelay: 2,
          }}
        />
      </motion.div>
    </motion.div>
  );
};

const StepCard = ({ number, icon, title, description, isInView }) => {
  return (
    <motion.div
      className="relative"
      initial={{ opacity: 0, y: 30 }}
      animate={isInView ? { opacity: 1, y: 0 } : { opacity: 0, y: 30 }}
      transition={{ duration: 0.5, delay: number * 0.1 }}
    >
      <div className="glass-effect rounded-xl p-6 relative z-10 card-3d">
        <div className="flex items-start gap-4">
          <div className="relative">
            <div className="w-16 h-16 rounded-full bg-gradient-to-br from-primary to-primary/50 flex items-center justify-center font-bold text-xl text-white shadow-lg">
              {icon}
            </div>
            <div className="absolute -left-2 -top-2 w-6 h-6 rounded-full bg-gradient-to-br from-primary to-secondary flex items-center justify-center text-xs font-bold">
              {number}
            </div>
          </div>
          <div>
            <h3 className="text-xl font-bold mb-2 gradient-text">{title}</h3>
            <p className="text-muted">{description}</p>
          </div>
        </div>

        {/* Glowing accent in the corner */}
        <div className="absolute -bottom-2 -right-2 w-20 h-20 rounded-full bg-gradient-to-br from-primary/10 to-secondary/10 blur-xl"></div>
      </div>

      {number < 4 && <ConnectionLine isInView={isInView} number={number} />}
    </motion.div>
  );
};

// 3D Process diagram in the center
const ProcessDiagram = ({ isInView }) => {
  return (
    <motion.div
      className="my-16 relative h-64 md:h-72"
      initial={{ opacity: 0 }}
      animate={isInView ? { opacity: 1 } : { opacity: 0 }}
      transition={{ duration: 0.8, delay: 0.5 }}
    >
      {/* Center node */}
      <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2">
        <motion.div
          className="w-24 h-24 rounded-full bg-gradient-to-br from-primary to-secondary relative flex items-center justify-center glow"
          animate={{
            boxShadow: [
              "0 0 20px 5px rgba(13, 186, 103, 0.3)",
              "0 0 30px 8px rgba(13, 186, 103, 0.5)",
              "0 0 20px 5px rgba(13, 186, 103, 0.3)",
            ],
          }}
          transition={{ duration: 2, repeat: Infinity }}
        >
          <span className="text-4xl">🌱</span>
        </motion.div>
      </div>

      {/* Orbiting nodes */}
      {[0, 1, 2, 3].map((i) => (
        <motion.div
          key={i}
          className="absolute top-1/2 left-1/2"
          style={{
            width: 180 + i * 40,
            height: 180 + i * 40,
            borderRadius: "50%",
            border: "1px dashed rgba(9, 238, 180, 0.2)",
          }}
          initial={{ opacity: 0, scale: 0.8 }}
          animate={{ opacity: 1, scale: 1, rotate: 360 }}
          transition={{
            duration: 20 + i * 5,
            delay: i * 0.2,
            repeat: Infinity,
            ease: "linear",
          }}
        >
          <motion.div
            className="absolute glass-effect w-10 h-10 rounded-full flex items-center justify-center"
            style={{
              left: `${Math.cos((Math.PI * 2 * i) / 4) * 50 + 50}%`,
              top: `${Math.sin((Math.PI * 2 * i) / 4) * 50 + 50}%`,
              transform: "translate(-50%, -50%)",
            }}
          >
            {i === 0 && <FaLink className="text-secondary" />}
            {i === 1 && <FaLock className="text-secondary" />}
            {i === 2 && <FaCoins className="text-secondary" />}
            {i === 3 && <FaExchangeAlt className="text-secondary" />}
          </motion.div>
        </motion.div>
      ))}
    </motion.div>
  );
};

const HowItWorks = () => {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true, margin: "-100px" });

  const steps = [
    {
      icon: <FaLink className="text-white" />,
      title: "Connect",
      description:
        "Connect your wallet to the LendX platform and authorize access to your preferred blockchain networks.",
    },
    {
      icon: <FaLock className="text-white" />,
      title: "Deposit Collateral",
      description:
        "Lock your crypto assets as collateral, keeping full ownership while accessing liquidity.",
    },
    {
      icon: <FaCoins className="text-white" />,
      title: "Borrow",
      description:
        "Access stablecoins or other supported assets at competitive interest rates, all without selling your holdings.",
    },
    {
      icon: <FaExchangeAlt className="text-white" />,
      title: "Repay or Refinance",
      description:
        "Repay your loan anytime or refinance as needed. Your collateral is released back to your wallet upon full repayment.",
    },
  ];

  return (
    <section id="how-it-works" className="py-20 relative overflow-hidden">
      <div className="absolute inset-0 z-0 gradient-bg"></div>

      {/* Floating eco particles */}
      <div className="eco-particles">
        {Array.from({ length: 10 }).map((_, i) => (
          <div
            key={i}
            className="eco-particle"
            style={{
              width: `${Math.random() * 6 + 3}px`,
              height: `${Math.random() * 6 + 3}px`,
              left: `${Math.random() * 100}%`,
              animationDelay: `${Math.random() * 15}s`,
              animationDuration: `${Math.random() * 10 + 10}s`,
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
            How <span className="gradient-text">It Works</span>
          </h2>
          <p className="text-muted max-w-2xl mx-auto">
            LendX streamlines the lending process with a simple, intuitive
            workflow designed to maximize capital efficiency and minimize
            friction.
          </p>
        </motion.div>

        {/* 3D Process diagram (for larger screens) */}
        <div className="hidden md:block">
          <ProcessDiagram isInView={isInView} />
        </div>

        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8 mt-8">
          {steps.map((step, index) => (
            <StepCard
              key={index}
              number={index + 1}
              icon={step.icon}
              title={step.title}
              description={step.description}
              isInView={isInView}
            />
          ))}
        </div>

        <motion.div
          className="mt-16 text-center"
          initial={{ opacity: 0, y: 20 }}
          animate={isInView ? { opacity: 1, y: 0 } : { opacity: 0, y: 20 }}
          transition={{ duration: 0.5, delay: 0.6 }}
        >
          <motion.button
            className="px-8 py-3 bg-gradient-to-r from-primary to-secondary rounded-lg text-white font-medium hover:opacity-90 transition-all"
            whileHover={{
              scale: 1.05,
              boxShadow: "0 0 15px rgba(13, 186, 103, 0.5)",
            }}
            whileTap={{ scale: 0.95 }}
          >
            Get Started
          </motion.button>
        </motion.div>
      </div>
    </section>
  );
};

export default HowItWorks;

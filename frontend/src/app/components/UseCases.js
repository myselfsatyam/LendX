"use client";

import { useRef } from "react";
import { motion, useInView } from "framer-motion";
import {
  FaUser,
  FaMoneyBillWave,
  FaChartLine,
  FaShieldAlt,
} from "react-icons/fa";

// 3D Floating cube with gradient faces
const GradientCube = () => {
  return (
    <div
      className="relative w-20 h-20 mx-auto floating"
      style={{ animationDuration: "8s", perspective: "1000px" }}
    >
      <motion.div
        className="absolute inset-0"
        animate={{
          rotateX: [0, 360],
          rotateY: [0, 360],
        }}
        transition={{
          duration: 20,
          repeat: Infinity,
          ease: "linear",
        }}
        style={{ transformStyle: "preserve-3d" }}
      >
        {/* Front face */}
        <div
          className="absolute inset-0 bg-gradient-to-br from-primary to-secondary opacity-70"
          style={{ transform: "translateZ(10px)" }}
        />

        {/* Back face */}
        <div
          className="absolute inset-0 bg-gradient-to-tr from-primary to-accent opacity-70"
          style={{ transform: "translateZ(-10px) rotateY(180deg)" }}
        />

        {/* Left face */}
        <div
          className="absolute inset-0 bg-gradient-to-r from-primary to-card opacity-70"
          style={{ transform: "rotateY(-90deg) translateZ(10px)" }}
        />

        {/* Right face */}
        <div
          className="absolute inset-0 bg-gradient-to-l from-secondary to-card opacity-70"
          style={{ transform: "rotateY(90deg) translateZ(10px)" }}
        />

        {/* Top face */}
        <div
          className="absolute inset-0 bg-gradient-to-b from-secondary to-primary opacity-70"
          style={{ transform: "rotateX(90deg) translateZ(10px)" }}
        />

        {/* Bottom face */}
        <div
          className="absolute inset-0 bg-gradient-to-t from-accent to-primary opacity-70"
          style={{ transform: "rotateX(-90deg) translateZ(10px)" }}
        />
      </motion.div>
    </div>
  );
};

const UseCaseCard = ({
  icon,
  title,
  userType,
  description,
  isInView,
  index,
}) => {
  return (
    <motion.div
      className="glass-effect rounded-xl h-full card-3d overflow-hidden relative"
      initial={{ opacity: 0, x: index % 2 === 0 ? -20 : 20 }}
      animate={
        isInView
          ? { opacity: 1, x: 0 }
          : { opacity: 0, x: index % 2 === 0 ? -20 : 20 }
      }
      transition={{ duration: 0.5, delay: index * 0.1 }}
      whileHover={{ translateY: -8 }}
    >
      {/* Animated gradient background */}
      <div className="absolute inset-0 opacity-10">
        <div className="absolute inset-0 bg-gradient-to-br from-primary via-transparent to-secondary animate-gradient"></div>
      </div>

      <div className="p-6 border-b border-border relative z-10">
        <div className="flex items-center gap-3 mb-4">
          <div className="w-10 h-10 rounded-full bg-gradient-to-br from-primary to-secondary flex items-center justify-center text-white shadow-md">
            {icon}
          </div>
          <h3 className="text-xl font-bold gradient-text">{title}</h3>
        </div>
        <span className="text-xs px-3 py-1 bg-primary/10 rounded-full text-secondary">
          {userType}
        </span>
      </div>
      <div className="p-6 relative z-10">
        <p className="text-muted">{description}</p>
      </div>

      {/* Corner decoration */}
      <div className="absolute bottom-0 right-0 w-20 h-20 overflow-hidden">
        <div className="absolute bottom-0 right-0 w-16 h-16 bg-gradient-to-tl from-primary/40 to-transparent transform rotate-45 translate-x-8 translate-y-8"></div>
      </div>
    </motion.div>
  );
};

const UseCases = () => {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true, margin: "-100px" });

  const useCases = [
    {
      icon: <FaUser />,
      title: "Long-Term Holders",
      userType: "Borrowers",
      description:
        "Access liquidity without selling your crypto assets. Keep your long-term investment strategy intact while using your holdings as collateral for loans.",
    },
    {
      icon: <FaChartLine />,
      title: "Yield Seekers",
      userType: "Liquidity Providers",
      description:
        "Earn attractive yields by providing liquidity to the platform. Benefit from the platform's robust risk management system while generating passive income.",
    },
    {
      icon: <FaMoneyBillWave />,
      title: "Tax-Efficient Financing",
      userType: "Borrowers",
      description:
        "Avoid triggering taxable events by borrowing against your assets instead of selling them. Maintain your exposure to potential upside while accessing funds.",
    },
    {
      icon: <FaShieldAlt />,
      title: "Institutional Providers",
      userType: "Liquidity Providers",
      description:
        "Participate in a growing ecosystem with institutional-grade security and risk management. Deploy capital with confidence across multiple chains.",
    },
  ];

  // Floating elements for decoration
  const floatingElements = [
    { top: "15%", left: "8%", size: 6, delay: 0, duration: 15 },
    { top: "65%", left: "5%", size: 10, delay: 2, duration: 20 },
    { top: "30%", right: "8%", size: 8, delay: 1, duration: 18 },
    { top: "80%", right: "12%", size: 12, delay: 3, duration: 25 },
  ];

  return (
    <section id="use-cases" className="py-20 relative overflow-hidden">
      <div className="absolute inset-0 z-0 gradient-bg"></div>

      {/* Decorative floating elements */}
      {floatingElements.map((el, i) => (
        <div
          key={i}
          className="absolute rounded-full bg-gradient-to-br from-primary/20 to-secondary/20 blur-xl"
          style={{
            top: el.top,
            left: el.left,
            right: el.right,
            width: `${el.size}rem`,
            height: `${el.size}rem`,
            animation: `float ${el.duration}s ease-in-out ${el.delay}s infinite`,
          }}
        />
      ))}

      {/* Eco particles */}
      <div className="eco-particles">
        {Array.from({ length: 15 }).map((_, i) => (
          <div
            key={i}
            className="eco-particle"
            style={{
              width: `${Math.random() * 5 + 3}px`,
              height: `${Math.random() * 5 + 3}px`,
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
            <span className="gradient-text">Use Cases</span>
          </h2>
          <p className="text-muted max-w-2xl mx-auto">
            Discover how different users leverage LendX to achieve their
            financial goals without compromising their long-term crypto
            strategy.
          </p>

          {/* 3D cube animation */}
          <div className="mt-8">
            <GradientCube />
          </div>
        </motion.div>

        <div className="grid md:grid-cols-2 gap-8 mt-12">
          {useCases.map((useCase, index) => (
            <UseCaseCard
              key={index}
              index={index}
              icon={useCase.icon}
              title={useCase.title}
              userType={useCase.userType}
              description={useCase.description}
              isInView={isInView}
            />
          ))}
        </div>

        <motion.div
          className="mt-20 glass-effect rounded-xl p-8 card-3d"
          initial={{ opacity: 0, y: 20 }}
          animate={isInView ? { opacity: 1, y: 0 } : { opacity: 0, y: 20 }}
          transition={{ duration: 0.5, delay: 0.4 }}
          whileHover={{ translateY: -5 }}
        >
          <div className="flex flex-col md:flex-row items-center justify-between gap-8">
            <div>
              <h3 className="text-2xl font-bold mb-2 gradient-text">
                Ready to get started?
              </h3>
              <p className="text-muted">
                Join thousands of users already benefiting from LendX.
              </p>
            </div>
            <motion.button
              className="whitespace-nowrap px-8 py-3 bg-gradient-to-r from-primary to-secondary rounded-lg text-white font-medium hover:opacity-90 transition-all"
              whileHover={{
                scale: 1.05,
                boxShadow: "0 0 15px rgba(13, 186, 103, 0.5)",
              }}
              whileTap={{ scale: 0.95 }}
            >
              Launch App
            </motion.button>
          </div>

          {/* Decorative corner elements */}
          <div className="absolute -top-4 -left-4 w-16 h-16 bg-primary/30 rounded-full blur-xl"></div>
          <div className="absolute -bottom-6 -right-6 w-20 h-20 bg-secondary/30 rounded-full blur-xl"></div>
        </motion.div>
      </div>
    </section>
  );
};

export default UseCases;

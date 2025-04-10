"use client";

import Link from "next/link";
import { motion } from "framer-motion";
import {
  FaTwitter,
  FaGithub,
  FaDiscord,
  FaTelegramPlane,
  FaLeaf,
} from "react-icons/fa";

// 3D logo component
const Logo3D = () => {
  return (
    <div className="relative h-14 w-40 mb-6 perspective-1000">
      <motion.div
        className="absolute inset-0 transform-style-3d"
        initial={{ rotateX: 25, rotateY: -25 }}
        animate={{
          rotateX: [25, 15, 25],
          rotateY: [-25, -15, -25],
          z: [0, 5, 0],
        }}
        transition={{
          duration: 6,
          repeat: Infinity,
          ease: "easeInOut",
        }}
      >
        <span className="text-3xl font-bold gradient-text">LendX</span>
        <div className="absolute -bottom-1 left-0 right-0 h-px bg-gradient-to-r from-primary via-secondary to-transparent"></div>
        <div className="absolute -left-2 -top-2">
          <FaLeaf className="text-primary text-opacity-80" />
        </div>
      </motion.div>
    </div>
  );
};

const SocialLink = ({ href, icon, delay }) => (
  <motion.a
    href={href}
    target="_blank"
    rel="noopener noreferrer"
    className="w-10 h-10 rounded-full bg-card flex items-center justify-center text-muted hover:text-white transition-colors overflow-hidden"
    whileHover={{ y: -3, boxShadow: "0 0 15px rgba(13, 186, 103, 0.3)" }}
    initial={{ opacity: 0, y: 10 }}
    animate={{ opacity: 1, y: 0 }}
    transition={{ delay, duration: 0.3 }}
  >
    <div className="absolute inset-0 bg-gradient-to-br from-primary/20 to-secondary/20 opacity-0 hover:opacity-100 transition-opacity duration-300"></div>
    <span className="relative z-10">{icon}</span>
  </motion.a>
);

const Footer = () => {
  return (
    <footer className="py-16 relative overflow-hidden">
      <div className="absolute inset-0 z-0 gradient-bg opacity-50"></div>
      <div className="absolute inset-0 z-0">
        <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-primary/30 to-transparent"></div>
        <div className="absolute -bottom-40 -right-40 w-80 h-80 bg-primary opacity-5 rounded-full filter blur-3xl"></div>
      </div>

      {/* Eco particles animation */}
      <div className="eco-particles">
        {Array.from({ length: 8 }).map((_, i) => (
          <div
            key={i}
            className="eco-particle"
            style={{
              width: `${Math.random() * 5 + 3}px`,
              height: `${Math.random() * 5 + 3}px`,
              left: `${Math.random() * 100}%`,
              animationDelay: `${Math.random() * 15}s`,
              animationDuration: `${Math.random() * 10 + 15}s`,
            }}
          />
        ))}
      </div>

      <div className="container mx-auto px-4 relative z-10">
        <div className="grid md:grid-cols-4 gap-10">
          <div className="col-span-1">
            <Logo3D />
            <p className="text-muted mb-6">
              Decentralized cross-chain lending platform built on the Sui
              blockchain with green sustainable technology.
            </p>
            <div className="flex space-x-4">
              <SocialLink
                href="https://twitter.com"
                icon={<FaTwitter />}
                delay={0.1}
              />
              <SocialLink
                href="https://github.com"
                icon={<FaGithub />}
                delay={0.2}
              />
              <SocialLink
                href="https://discord.com"
                icon={<FaDiscord />}
                delay={0.3}
              />
              <SocialLink
                href="https://telegram.org"
                icon={<FaTelegramPlane />}
                delay={0.4}
              />
            </div>
          </div>

          <div>
            <h3 className="font-bold mb-4 gradient-text">Product</h3>
            <ul className="space-y-2">
              {["Features", "App", "Documentation", "API"].map((item, i) => (
                <motion.li
                  key={i}
                  initial={{ opacity: 0, x: -10 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: 0.1 * i, duration: 0.3 }}
                >
                  <Link
                    href={item === "Features" ? "#features" : "#"}
                    className="text-muted hover:text-white transition-colors flex items-center"
                  >
                    <span className="w-1.5 h-1.5 rounded-full bg-primary mr-2"></span>
                    {item}
                  </Link>
                </motion.li>
              ))}
            </ul>
          </div>

          <div>
            <h3 className="font-bold mb-4 gradient-text">Resources</h3>
            <ul className="space-y-2">
              {["Whitepaper", "Blog", "Community", "Roadmap"].map((item, i) => (
                <motion.li
                  key={i}
                  initial={{ opacity: 0, x: -10 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: 0.2 + 0.1 * i, duration: 0.3 }}
                >
                  <Link
                    href="#"
                    className="text-muted hover:text-white transition-colors flex items-center"
                  >
                    <span className="w-1.5 h-1.5 rounded-full bg-secondary mr-2"></span>
                    {item}
                  </Link>
                </motion.li>
              ))}
            </ul>
          </div>

          <div>
            <h3 className="font-bold mb-4 gradient-text">Company</h3>
            <ul className="space-y-2">
              {["About", "Careers", "Contact", "Press Kit"].map((item, i) => (
                <motion.li
                  key={i}
                  initial={{ opacity: 0, x: -10 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: 0.3 + 0.1 * i, duration: 0.3 }}
                >
                  <Link
                    href="#"
                    className="text-muted hover:text-white transition-colors flex items-center"
                  >
                    <span className="w-1.5 h-1.5 rounded-full bg-accent mr-2"></span>
                    {item}
                  </Link>
                </motion.li>
              ))}
            </ul>
          </div>
        </div>

        <div className="border-t border-primary/20 mt-12 pt-8 flex flex-col md:flex-row justify-between items-center">
          <p className="text-muted text-sm">
            © {new Date().getFullYear()} LendX. All rights reserved.
          </p>
          <div className="flex space-x-6 mt-4 md:mt-0">
            {["Terms of Service", "Privacy Policy", "Cookie Policy"].map(
              (item, i) => (
                <Link
                  key={i}
                  href="#"
                  className="text-muted hover:text-white text-sm transition-colors relative group"
                >
                  {item}
                  <span className="absolute -bottom-1 left-0 right-0 h-px bg-gradient-to-r from-primary to-secondary scale-x-0 group-hover:scale-x-100 transition-transform duration-300 origin-left"></span>
                </Link>
              )
            )}
          </div>
        </div>
      </div>
    </footer>
  );
};

export default Footer;

import type { Config } from "tailwindcss";

export default {
  content: ["./index.html", "./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        runway: {
          bg: "#0F1219",
          surface: "#141924",
          card: "#1A2233",
          border: "#1E2D45",
          blue: "#386BF2",
          purple: "#614BE1",
          teal: "#00D4FF",
          green: "#00E676",
          yellow: "#FFD740",
          orange: "#FF9100",
          red: "#FF3D57",
          muted: "#8099B3",
          dim: "#4A5568",
        },
      },
      fontFamily: {
        mono: ['"JetBrains Mono"', "ui-monospace", "monospace"],
        sans: ['"Space Grotesk"', "system-ui", "sans-serif"],
      },
      letterSpacing: {
        widest2: "0.2em",
        widest3: "0.3em",
      },
      backgroundImage: {
        "gradient-runway": "linear-gradient(135deg, #386BF2 0%, #614BE1 100%)",
        "gradient-danger": "linear-gradient(135deg, #FF3D57 0%, #FF9100 100%)",
        "gradient-night": "linear-gradient(180deg, #0F1219 0%, #0A0D14 100%)",
      },
      animation: {
        "pulse-slow": "pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite",
        "pulse-fast": "pulse 0.8s cubic-bezier(0.4, 0, 0.6, 1) infinite",
        float: "float 6s ease-in-out infinite",
        scan: "scan 3s linear infinite",
        flicker: "flicker 0.15s infinite",
        "runway-lights": "runwayLights 1.5s linear infinite",
        "slide-up": "slideUp 0.6s ease-out forwards",
        "glow-blue": "glowBlue 2s ease-in-out infinite alternate",
        "glow-green": "glowGreen 1s ease-in-out infinite alternate",
        "text-blink": "textBlink 1s step-end infinite",
      },
      keyframes: {
        float: {
          "0%, 100%": { transform: "translateY(0px) rotate(0deg)" },
          "50%": { transform: "translateY(-20px) rotate(1deg)" },
        },
        scan: {
          "0%": { transform: "rotate(0deg)" },
          "100%": { transform: "rotate(360deg)" },
        },
        flicker: {
          "0%, 100%": { opacity: "1" },
          "50%": { opacity: "0.8" },
        },
        runwayLights: {
          "0%": { backgroundPosition: "0% 0%" },
          "100%": { backgroundPosition: "0% 100%" },
        },
        slideUp: {
          "0%": { opacity: "0", transform: "translateY(40px)" },
          "100%": { opacity: "1", transform: "translateY(0)" },
        },
        glowBlue: {
          "0%": { boxShadow: "0 0 5px #386BF2, 0 0 10px #386BF2" },
          "100%": {
            boxShadow: "0 0 20px #386BF2, 0 0 40px #614BE1, 0 0 60px #614BE1",
          },
        },
        glowGreen: {
          "0%": { boxShadow: "0 0 5px #00E676" },
          "100%": { boxShadow: "0 0 20px #00E676, 0 0 40px #00E676" },
        },
        textBlink: {
          "0%, 100%": { opacity: "1" },
          "50%": { opacity: "0" },
        },
      },
    },
  },
  plugins: [],
} satisfies Config;

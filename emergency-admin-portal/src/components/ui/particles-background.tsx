import React, { useEffect, useRef } from "react";

interface Particle {
  x: number;
  y: number;
  vx: number;
  vy: number;
  size: number;
  opacity: number;
  color: string;
}

interface ParticlesBackgroundProps {
  className?: string;
  particleCount?: number;
  colors?: string[];
  speed?: number;
  size?: { min: number; max: number };
  opacity?: { min: number; max: number };
  connections?: boolean;
  connectionDistance?: number;
  showWaves?: boolean;
  waveCount?: number;
  waveAmplitude?: number;
  waveFrequency?: number;
  waveSpeed?: number;
}

export const ParticlesBackground: React.FC<ParticlesBackgroundProps> = ({
  className = "",
  particleCount = 80,
  colors = ["#3B82F6", "#6366F1", "#8B5CF6", "#A855F7", "#EC4899"],
  speed = 0.5,
  size = { min: 1, max: 3 },
  opacity = { min: 0.3, max: 0.8 },
  connections = true,
  connectionDistance = 120,
  showWaves = true,
  waveCount = 5,
  waveAmplitude = 60,
  waveFrequency = 0.02,
  waveSpeed = 0.01,
}) => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const animationRef = useRef<number>();
  const particlesRef = useRef<Particle[]>([]);
  const mouseRef = useRef({ x: 0, y: 0 });
  const timeRef = useRef(0);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    // Set canvas size
    const resizeCanvas = () => {
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
    };

    resizeCanvas();
    window.addEventListener("resize", resizeCanvas);

    // Initialize particles
    const initParticles = () => {
      particlesRef.current = [];
      for (let i = 0; i < particleCount; i++) {
        particlesRef.current.push({
          x: Math.random() * canvas.width,
          y: Math.random() * canvas.height,
          vx: (Math.random() - 0.5) * speed,
          vy: (Math.random() - 0.5) * speed,
          size: Math.random() * (size.max - size.min) + size.min,
          opacity: Math.random() * (opacity.max - opacity.min) + opacity.min,
          color: colors[Math.floor(Math.random() * colors.length)],
        });
      }
    };

    initParticles();

    // Mouse interaction
    const handleMouseMove = (e: MouseEvent) => {
      mouseRef.current.x = e.clientX;
      mouseRef.current.y = e.clientY;
    };

    canvas.addEventListener("mousemove", handleMouseMove);

    // Draw flowing wave lines
    const drawWaves = () => {
      if (!showWaves) return;

      timeRef.current += waveSpeed;

      for (let i = 0; i < waveCount; i++) {
        const waveOffset = (i / waveCount) * Math.PI * 2;
        const waveOpacity = 0.1 + (i / waveCount) * 0.15;

        ctx.beginPath();
        ctx.strokeStyle = colors[i % colors.length];
        ctx.globalAlpha = waveOpacity;
        ctx.lineWidth = 1.5;

        // Create wave path from top-left to bottom-center to top-right
        const points: { x: number; y: number }[] = [];
        const totalSteps = 200;

        for (let step = 0; step <= totalSteps; step++) {
          const progress = step / totalSteps;

          // Base path: parabolic curve from top-left to bottom-center to top-right
          let baseX = progress * canvas.width;
          let baseY: number;

          if (progress <= 0.5) {
            // First half: top-left to bottom-center (converging)
            const localProgress = progress * 2; // 0 to 1
            baseY = localProgress * canvas.height * 0.8; // Go down to 80% of height
          } else {
            // Second half: bottom-center to top-right (diverging)
            const localProgress = (progress - 0.5) * 2; // 0 to 1
            baseY = canvas.height * 0.8 * (1 - localProgress); // Go up from 80% to 0%
          }

          // Add wave oscillation
          const waveX =
            Math.sin(progress * Math.PI * 4 + waveOffset + timeRef.current) *
            waveAmplitude;
          const waveY =
            Math.cos(
              progress * Math.PI * 6 + waveOffset + timeRef.current * 0.7
            ) *
            (waveAmplitude * 0.5);

          // Apply convergence/divergence effect
          let convergenceFactor: number;
          if (progress <= 0.5) {
            // Converging: reduce wave amplitude as we approach center
            convergenceFactor = 1 - progress * 0.6; // Reduce to 40% at center
          } else {
            // Diverging: increase wave amplitude as we move away from center
            convergenceFactor = 0.4 + (progress - 0.5) * 1.2; // Increase from 40% back to 100%
          }

          points.push({
            x: baseX + waveX * convergenceFactor,
            y: baseY + waveY * convergenceFactor,
          });
        }

        // Draw the wave path
        if (points.length > 0) {
          ctx.moveTo(points[0].x, points[0].y);

          // Use quadratic curves for smooth wave lines
          for (let j = 1; j < points.length - 1; j++) {
            const currentPoint = points[j];
            const nextPoint = points[j + 1];
            const controlX = (currentPoint.x + nextPoint.x) / 2;
            const controlY = (currentPoint.y + nextPoint.y) / 2;

            ctx.quadraticCurveTo(
              currentPoint.x,
              currentPoint.y,
              controlX,
              controlY
            );
          }

          // Draw the last segment
          if (points.length > 1) {
            const lastPoint = points[points.length - 1];
            ctx.lineTo(lastPoint.x, lastPoint.y);
          }
        }

        ctx.stroke();
      }

      ctx.globalAlpha = 1; // Reset alpha
    };

    // Animation loop
    const animate = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);

      // Draw flowing waves first (behind particles)
      drawWaves();

      // Update and draw particles
      particlesRef.current.forEach((particle, index) => {
        // Update position
        particle.x += particle.vx;
        particle.y += particle.vy;

        // Bounce off edges
        if (particle.x < 0 || particle.x > canvas.width) {
          particle.vx *= -1;
        }
        if (particle.y < 0 || particle.y > canvas.height) {
          particle.vy *= -1;
        }

        // Keep particles in bounds
        particle.x = Math.max(0, Math.min(canvas.width, particle.x));
        particle.y = Math.max(0, Math.min(canvas.height, particle.y));

        // Mouse interaction - attract particles to mouse
        const dx = mouseRef.current.x - particle.x;
        const dy = mouseRef.current.y - particle.y;
        const distance = Math.sqrt(dx * dx + dy * dy);

        if (distance < 100) {
          const force = (100 - distance) / 100;
          particle.vx += (dx / distance) * force * 0.01;
          particle.vy += (dy / distance) * force * 0.01;
        }

        // Apply friction
        particle.vx *= 0.99;
        particle.vy *= 0.99;

        // Draw particle
        ctx.beginPath();
        ctx.arc(particle.x, particle.y, particle.size, 0, Math.PI * 2);
        ctx.fillStyle = particle.color;
        ctx.globalAlpha = particle.opacity;
        ctx.fill();

        // Draw connections
        if (connections) {
          particlesRef.current.slice(index + 1).forEach((otherParticle) => {
            const dx = particle.x - otherParticle.x;
            const dy = particle.y - otherParticle.y;
            const distance = Math.sqrt(dx * dx + dy * dy);

            if (distance < connectionDistance) {
              ctx.beginPath();
              ctx.moveTo(particle.x, particle.y);
              ctx.lineTo(otherParticle.x, otherParticle.y);
              ctx.strokeStyle = particle.color;
              ctx.globalAlpha = (1 - distance / connectionDistance) * 0.2;
              ctx.lineWidth = 0.5;
              ctx.stroke();
            }
          });
        }
      });

      ctx.globalAlpha = 1;
      animationRef.current = requestAnimationFrame(animate);
    };

    animate();

    return () => {
      window.removeEventListener("resize", resizeCanvas);
      canvas.removeEventListener("mousemove", handleMouseMove);
      if (animationRef.current) {
        cancelAnimationFrame(animationRef.current);
      }
    };
  }, [
    particleCount,
    colors,
    speed,
    size,
    opacity,
    connections,
    connectionDistance,
  ]);

  return (
    <canvas
      ref={canvasRef}
      className={`fixed inset-0 pointer-events-none z-0 ${className}`}
      style={{ background: "transparent" }}
    />
  );
};

// Preset configurations for different themes
export const ParticlePresets = {
  emergency: {
    colors: ["#EF4444", "#F97316", "#EAB308", "#DC2626", "#B91C1C"],
    particleCount: 60,
    speed: 0.3,
    connectionDistance: 100,
    showWaves: true,
    waveCount: 4,
    waveAmplitude: 50,
    waveSpeed: 0.008,
  },
  ocean: {
    colors: ["#0EA5E9", "#0284C7", "#0369A1", "#075985", "#0C4A6E"],
    particleCount: 70,
    speed: 0.4,
    connectionDistance: 110,
    showWaves: true,
    waveCount: 6,
    waveAmplitude: 70,
    waveSpeed: 0.012,
  },
  forest: {
    colors: ["#22C55E", "#16A34A", "#15803D", "#166534", "#14532D"],
    particleCount: 50,
    speed: 0.2,
    connectionDistance: 130,
    showWaves: true,
    waveCount: 3,
    waveAmplitude: 40,
    waveSpeed: 0.006,
  },
  sunset: {
    colors: ["#F59E0B", "#F97316", "#EF4444", "#EC4899", "#8B5CF6"],
    particleCount: 80,
    speed: 0.5,
    connectionDistance: 120,
    showWaves: true,
    waveCount: 7,
    waveAmplitude: 80,
    waveSpeed: 0.015,
  },
  professional: {
    colors: ["#3B82F6", "#6366F1", "#8B5CF6", "#1E40AF", "#1E3A8A"],
    particleCount: 60,
    speed: 0.3,
    connectionDistance: 100,
    showWaves: true,
    waveCount: 5,
    waveAmplitude: 60,
    waveSpeed: 0.01,
  },
};

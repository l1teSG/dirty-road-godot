import { useEffect, useRef } from 'react';

/**
 * Fondo de la landing: reproducción del menú de inicio del juego.
 *
 * Se compone de las tres piezas de `dirty-road/ui/main/main.tscn`:
 *   1. `ui/main/fondo.gdshader`  → ruido verde + vetas diagonales + brillo neón.
 *   2. `WorldEnvironment` (glow) → bloom suave (segunda pasada de blur).
 *   3. `CPUParticles2D "Particulas"` → esporas verdes flotando.
 *
 * La paleta y la matemática del shader son las EXACTAS del juego; no se adaptan
 * al tema de la web para que el fondo se sienta como el menú real.
 *
 * Si no hay WebGL, el shader se oculta y queda el color abisal de respaldo
 * (las esporas siguen dibujándose).
 */

const VERT = `
attribute vec2 a_pos;
varying vec2 v_uv;
void main() {
  v_uv = a_pos * 0.5 + 0.5;
  gl_Position = vec4(a_pos, 0.0, 1.0);
}
`;

// Port 1:1 de ui/main/fondo.gdshader (misma matemática y colores).
const FRAG_BASE = `
precision mediump float;
uniform vec2 u_res;
uniform float u_time;
uniform float u_scroll;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}
float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  float a = hash(i);
  float b = hash(i + vec2(1.0, 0.0));
  float c = hash(i + vec2(0.0, 1.0));
  float d = hash(i + vec2(1.0, 1.0));
  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}
void main() {
  vec2 uv = gl_FragCoord.xy / u_res;
  // El fondo se desplaza con el scroll para ligarlo a la navegación.
  uv += vec2(0.0, u_scroll * 0.12);
  float t = u_time * 0.06;

  // Dos capas de ruido en movimiento -> manchas orgánicas.
  float n1 = noise(uv * 3.0 + vec2(t, t * 0.7));
  float n2 = noise(uv * 6.0 - vec2(t * 0.5, t * 1.1));
  float m = clamp(n1 * 0.65 + n2 * 0.35, 0.0, 1.0);

  vec3 color_a = vec3(0.0196, 0.0627, 0.0431);
  vec3 color_b = vec3(0.0588, 0.1647, 0.1020);
  vec3 color_brillo = vec3(0.6, 1.0, 0.2);

  vec3 col = mix(color_a, color_b, m);

  // Vetas diagonales suaves en movimiento.
  float veta = sin((uv.x + uv.y) * 8.0 - t * 6.0) * 0.5 + 0.5;
  col += color_b * veta * 0.25;

  // Brillo verdoso en las crestas del ruido.
  float brillo = smoothstep(0.78, 1.0, m);
  col += color_brillo * brillo * 0.18;

  gl_FragColor = vec4(col, 1.0);
}
`;

// Pasada 2: bloom barato sobre la textura del shader (el glow del WorldEnvironment).
const FRAG_COMPOSITE = `
precision mediump float;
varying vec2 v_uv;
uniform sampler2D u_tex;
uniform vec2 u_texel;
uniform float u_strength;

void main() {
  vec3 base = texture2D(u_tex, v_uv).rgb;

  vec3 bloom = vec3(0.0);
  float total = 0.0;
  for (int y = -2; y <= 2; y++) {
    for (int x = -2; x <= 2; x++) {
      vec2 off = vec2(float(x), float(y)) * u_texel * 2.0;
      vec3 c = texture2D(u_tex, v_uv + off).rgb;
      float w = 1.0 / (1.0 + float(x * x + y * y));
      float lum = max(max(c.r, c.g), c.b);
      bloom += c * smoothstep(0.2, 0.6, lum) * w;
      total += w;
    }
  }
  bloom /= total;

  gl_FragColor = vec4(base + bloom * u_strength, 1.0);
}
`;

function compile(gl: WebGLRenderingContext, type: number, src: string) {
  const sh = gl.createShader(type)!;
  gl.shaderSource(sh, src);
  gl.compileShader(sh);
  if (!gl.getShaderParameter(sh, gl.COMPILE_STATUS)) {
    gl.deleteShader(sh);
    return null;
  }
  return sh;
}

function link(gl: WebGLRenderingContext, vs: WebGLShader, fs: WebGLShader) {
  const prog = gl.createProgram()!;
  gl.attachShader(prog, vs);
  gl.attachShader(prog, fs);
  gl.linkProgram(prog);
  if (!gl.getProgramParameter(prog, gl.LINK_STATUS)) {
    gl.deleteProgram(prog);
    return null;
  }
  return prog;
}

/** Esporas flotando (port de CPUParticles2D "Particulas"). */
const SPORE_COLOR = '153, 255, 51'; // #99ff33

export default function FondoMenu() {
  const glRef = useRef<HTMLCanvasElement>(null);
  const sporeRef = useRef<HTMLCanvasElement>(null);

  // --- Shader + bloom ---
  useEffect(() => {
    const canvas = glRef.current;
    if (!canvas) return;
    const gl = canvas.getContext('webgl', { antialias: false, alpha: false });
    if (!gl) {
      canvas.style.display = 'none';
      return;
    }

    const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    const vs = compile(gl, gl.VERTEX_SHADER, VERT);
    const fsBase = compile(gl, gl.FRAGMENT_SHADER, FRAG_BASE);
    const fsComp = compile(gl, gl.FRAGMENT_SHADER, FRAG_COMPOSITE);
    const progBase = vs && fsBase ? link(gl, vs, fsBase) : null;
    const progComp = vs && fsComp ? link(gl, vs, fsComp) : null;
    if (!progBase) {
      canvas.style.display = 'none';
      return;
    }

    const quad = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, quad);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 1, -1, -1, 1, 1, 1]), gl.STATIC_DRAW);

    const useProgram = (prog: WebGLProgram) => {
      gl.useProgram(prog);
      const loc = gl.getAttribLocation(prog, 'a_pos');
      gl.bindBuffer(gl.ARRAY_BUFFER, quad);
      gl.enableVertexAttribArray(loc);
      gl.vertexAttribPointer(loc, 2, gl.FLOAT, false, 0, 0);
    };

    const baseU = {
      res: gl.getUniformLocation(progBase, 'u_res'),
      time: gl.getUniformLocation(progBase, 'u_time'),
      scroll: gl.getUniformLocation(progBase, 'u_scroll'),
    };
    const compU = progComp
      ? {
          tex: gl.getUniformLocation(progComp, 'u_tex'),
          texel: gl.getUniformLocation(progComp, 'u_texel'),
          strength: gl.getUniformLocation(progComp, 'u_strength'),
        }
      : null;

    // Objetivo a media resolución para el bloom.
    const tex = progComp ? gl.createTexture() : null;
    const fbo = progComp ? gl.createFramebuffer() : null;
    let fboOk = false;
    let texW = 1;
    let texH = 1;

    const dpr = Math.min(window.devicePixelRatio || 1, 2);

    const resize = () => {
      const w = Math.floor(window.innerWidth * dpr);
      const h = Math.floor(window.innerHeight * dpr);
      canvas.width = w;
      canvas.height = h;

      if (tex && fbo) {
        texW = Math.max(1, Math.floor(w / 2));
        texH = Math.max(1, Math.floor(h / 2));
        gl.bindTexture(gl.TEXTURE_2D, tex);
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, texW, texH, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
        gl.bindFramebuffer(gl.FRAMEBUFFER, fbo);
        gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, tex, 0);
        fboOk = gl.checkFramebufferStatus(gl.FRAMEBUFFER) === gl.FRAMEBUFFER_COMPLETE;
        gl.bindFramebuffer(gl.FRAMEBUFFER, null);
      }
    };

    const start = performance.now();
    const frame = (now: number) => {
      const t = (now - start) / 1000;
      const scroll = window.scrollY / (window.innerHeight || 1);

      if (fboOk && progComp && compU && tex) {
        // Paso 1: shader -> framebuffer (media resolución).
        gl.bindFramebuffer(gl.FRAMEBUFFER, fbo);
        gl.viewport(0, 0, texW, texH);
        useProgram(progBase);
        gl.uniform2f(baseU.res, texW, texH);
        gl.uniform1f(baseU.time, t);
        gl.uniform1f(baseU.scroll, scroll);
        gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);

        // Paso 2: bloom + composite -> pantalla.
        gl.bindFramebuffer(gl.FRAMEBUFFER, null);
        gl.viewport(0, 0, canvas.width, canvas.height);
        useProgram(progComp);
        gl.activeTexture(gl.TEXTURE0);
        gl.bindTexture(gl.TEXTURE_2D, tex);
        gl.uniform1i(compU.tex, 0);
        gl.uniform2f(compU.texel, 1 / texW, 1 / texH);
        gl.uniform1f(compU.strength, 0.9);
        gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
      } else {
        // Fallback sin bloom.
        gl.viewport(0, 0, canvas.width, canvas.height);
        useProgram(progBase);
        gl.uniform2f(baseU.res, canvas.width, canvas.height);
        gl.uniform1f(baseU.time, t);
        gl.uniform1f(baseU.scroll, scroll);
        gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
      }
    };

    resize();
    window.addEventListener('resize', resize);

    let raf = 0;
    if (reduce) {
      frame(start);
    } else {
      const loop = (now: number) => {
        frame(now);
        raf = requestAnimationFrame(loop);
      };
      raf = requestAnimationFrame(loop);
    }

    return () => {
      cancelAnimationFrame(raf);
      window.removeEventListener('resize', resize);
    };
  }, []);

  // --- Esporas ---
  useEffect(() => {
    const canvas = sporeRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    const COUNT = 48;

    let w = 0;
    let h = 0;

    interface Spore {
      x: number;
      y: number;
      r: number;
      vy: number;
      sway: number;
      phase: number;
      alpha: number;
    }

    const create = (spread: boolean): Spore => ({
      x: Math.random() * w,
      y: spread ? Math.random() * h : h + 20,
      r: (0.5 + Math.random() * 1.8) * dpr,
      vy: (8 + Math.random() * 24) * dpr,
      sway: (6 + Math.random() * 16) * dpr,
      phase: Math.random() * Math.PI * 2,
      alpha: 0.15 + Math.random() * 0.35,
    });

    let spores: Spore[] = [];

    const resize = () => {
      w = Math.floor(window.innerWidth * dpr);
      h = Math.floor(window.innerHeight * dpr);
      canvas.width = w;
      canvas.height = h;
      spores = Array.from({ length: COUNT }, () => create(true));
    };

    const draw = (dt: number) => {
      ctx.clearRect(0, 0, w, h);
      ctx.globalCompositeOperation = 'lighter';

      for (const s of spores) {
        if (!reduce) {
          s.y -= s.vy * dt;
          s.phase += dt * 1.5;
          if (s.y < -20) Object.assign(s, create(false));
        }

        const x = s.x + Math.sin(s.phase) * s.sway;
        const twinkle = 0.6 + 0.4 * Math.sin(s.phase * 2);
        const radius = s.r * 4;
        const g = ctx.createRadialGradient(x, s.y, 0, x, s.y, radius);
        g.addColorStop(0, `rgba(${SPORE_COLOR}, ${s.alpha * twinkle})`);
        g.addColorStop(1, `rgba(${SPORE_COLOR}, 0)`);
        ctx.fillStyle = g;
        ctx.beginPath();
        ctx.arc(x, s.y, radius, 0, Math.PI * 2);
        ctx.fill();
      }
    };

    resize();
    window.addEventListener('resize', resize);

    let raf = 0;
    if (reduce) {
      draw(0);
    } else {
      let last = performance.now();
      const loop = (now: number) => {
        const dt = Math.min((now - last) / 1000, 0.05);
        last = now;
        draw(dt);
        raf = requestAnimationFrame(loop);
      };
      raf = requestAnimationFrame(loop);
    }

    return () => {
      cancelAnimationFrame(raf);
      window.removeEventListener('resize', resize);
    };
  }, []);

  return (
    <div
      aria-hidden="true"
      className="pointer-events-none fixed inset-0 -z-10 overflow-hidden"
      style={{ backgroundColor: '#050a08' }}
    >
      <canvas ref={glRef} className="absolute inset-0 h-full w-full" />
      <canvas ref={sporeRef} className="absolute inset-0 h-full w-full" />
    </div>
  );
}

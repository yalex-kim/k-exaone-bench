

Here's a complete single-file HTML page that draws an animated pelican riding a bicycle as an SVG, with controls for pedal speed, three color palettes, and export options.

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Pelican on a Bicycle — SVG Studio</title>
<style>
  :root{
    --panel:#18212c;
    --panel-2:#202b39;
    --line:#2a3644;
    --text:#e9eff6;
    --muted:#93a3b5;
    --accent:#ffb703;
    --accent-ink:#2a1e00;
    --warn:#ffb703;
    --ok:#6ee7a8;
    --radius:16px;
  }
  *,*::before,*::after{box-sizing:border-box}
  body{
    margin:0;
    min-height:100vh;
    padding:clamp(16px,3vw,40px);
    color:var(--text);
    font-family:ui-sans-serif,system-ui,-apple-system,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
    background:
      radial-gradient(900px 500px at 12% -8%, #1e2c3c 0%, rgba(30,44,60,0) 62%),
      radial-gradient(700px 420px at 92% 4%, #2a2130 0%, rgba(42,33,48,0) 60%),
      linear-gradient(165deg,#0e131a,#111823 55%,#0c1117);
    background-attachment:fixed;
  }
  .page-head{max-width:1240px;margin:0 auto 20px}
  h1{margin:0 0 6px;font-size:clamp(1.5rem,3.4vw,2.15rem);letter-spacing:-.02em}
  .sub{margin:0;color:var(--muted);line-height:1.55;max-width:64ch;font-size:.95rem}
  .layout{
    max-width:1240px;margin:0 auto;display:grid;
    grid-template-columns:minmax(0,1fr) 320px;gap:22px;align-items:start;
  }
  @media (max-width:900px){ .layout{grid-template-columns:minmax(0,1fr)} }
  .stage-card{
    background:#f7fafc;border-radius:var(--radius);padding:14px;
    box-shadow:0 24px 48px -30px rgba(0,0,0,.9), 0 0 0 1px rgba(255,255,255,.06);
  }
  .stage svg{display:block;width:100%;height:auto;border-radius:10px}
  .fallback{margin:0;padding:28px 16px;text-align:center;color:var(--muted);font-size:.9rem}
  .caption{margin:10px 2px 0;color:var(--muted);font-size:.76rem;letter-spacing:.02em}
  .panel{
    background:var(--panel);border:1px solid var(--line);border-radius:var(--radius);
    padding:18px;display:flex;flex-direction:column;gap:16px;
    box-shadow:0 24px 48px -34px rgba(0,0,0,.9);
  }
  .control{display:flex;flex-direction:column;gap:8px}
  label,.label{
    font-size:.72rem;text-transform:uppercase;letter-spacing:.08em;color:var(--muted);
    display:flex;justify-content:space-between;align-items:baseline;gap:10px;
  }
  output{color:var(--accent);font-variant-numeric:tabular-nums;font-size:.8rem;letter-spacing:0}
  input[type=range]{width:100%;accent-color:var(--accent);cursor:pointer}
  .btn{
    appearance:none;font:inherit;font-size:.88rem;color:var(--text);background:var(--panel-2);
    border:1px solid var(--line);border-radius:10px;padding:10px 14px;cursor:pointer;
    transition:background .15s ease,border-color .15s ease,transform .06s ease;
  }
  .btn:hover{background:#26333f;border-color:#37475a}
  .btn:active{transform:translateY(1px)}
  .btn:focus-visible{outline:2px solid var(--accent);outline-offset:2px}
  .btn-primary{background:var(--accent);border-color:transparent;color:var(--accent-ink);font-weight
import { useEffect, useState } from "react";

export default function App() {
  const [status, setStatus] = useState("checking…");

  useEffect(() => {
    fetch("/api/health")
      .then((r) => r.json())
      .then((data: { status: string }) => setStatus(data.status))
      .catch(() => setStatus("API not reachable"));
  }, []);

  return (
    <main>
      <h1>__NAME__</h1>
      <p>API: {status}</p>
    </main>
  );
}

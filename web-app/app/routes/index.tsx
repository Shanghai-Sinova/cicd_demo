import { createFileRoute } from '@tanstack/react-router';

export const Route = createFileRoute('/')({
  component: Index,
});

function Index() {
  return (
    <main style={{ padding: '1.5rem', fontFamily: 'system-ui' }}>
      <h1>TanStack Start SSR</h1>
      <p>Hello, world — rendered on the server with TanStack Start.</p>
    </main>
  );
}

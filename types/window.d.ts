interface Window {
  workbox?: {
    addEventListener: (event: string, handler: () => void) => void;
    register: () => void;
    messageSkipWaiting: () => void;
  };
}

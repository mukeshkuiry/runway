import { useEffect, useRef, useState } from "react";

export function useInView(
  ref: React.RefObject<Element | null>,
  options: IntersectionObserverInit = {},
) {
  const [inView, setInView] = useState(false);
  const observerRef = useRef<IntersectionObserver | null>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    observerRef.current = new IntersectionObserver(([entry]) => {
      setInView(entry.isIntersecting);
    }, options);
    observerRef.current.observe(el);
    return () => observerRef.current?.disconnect();
  }, [ref, options.threshold]);

  return inView;
}

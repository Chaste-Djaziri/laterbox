// laterbox-web/src/components/marketing/DesignedToStayOutOfWaySection.tsx
import { InteractiveDashboardPreview } from './InteractiveDashboardPreview';

export function DesignedToStayOutOfWaySection() {
  return (
    <section className="overflow-hidden border-t border-[#e4e0d5] bg-[#faf8f5] px-4 py-24 text-[#171711] sm:px-6 sm:py-36 lg:px-8">
      <div className="mx-auto max-w-6xl text-center">
        <h2 className="text-center leading-none">
          <span className="block text-5xl font-black tracking-tight text-[#171711] sm:text-7xl lg:text-8xl">
            Designed to stay
          </span>
          <span className="mt-1 block font-serif text-5xl font-normal italic lowercase tracking-normal text-[#171711] sm:mt-2 sm:text-7xl lg:text-8xl">
            out of your way.
          </span>
        </h2>
        <p className="mx-auto mt-6 max-w-xl text-sm leading-7 text-[#6c6b63] sm:text-base">
          Take a look around. Search, schedule, and save something in this hands-on preview —
          no sign-in, no setup, and no changes to a real account.
        </p>

        <div className="mx-auto mt-12 max-w-6xl sm:mt-16">
          <InteractiveDashboardPreview />
        </div>
        <p className="mt-5 text-xs font-medium text-[#858a7d]">
          This is a product demo using sample data. Everything resets when you reload.
        </p>
      </div>
    </section>
  );
}

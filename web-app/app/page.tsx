import { HeatmapGrid } from "@/components/heatmap-grid"
import { Navigation } from "@/components/navigation"

export default function HeatmapPage() {
  return (
    <div className="min-h-screen">
      <Navigation />
      <main className="container mx-auto px-4 py-8">
        <div className="mb-6">
          <h1 className="text-3xl font-bold mb-2">Lifestreak</h1>
          <p className="text-muted-foreground">Rolling 90-day view</p>
        </div>
        <HeatmapGrid />
      </main>
    </div>
  )
}

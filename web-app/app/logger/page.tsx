import { Navigation } from "@/components/navigation"

export default function LoggerPage() {
  return (
    <div className="min-h-screen">
      <Navigation />
      <main className="container mx-auto px-4 py-8">
        <h1 className="text-3xl font-bold mb-6">Habit Logger</h1>
        <div className="space-y-4">
          {/* TODO: Habit list component */}
          <div className="p-4 border rounded-lg">
            <p className="text-muted-foreground">Habit logging UI goes here</p>
          </div>
        </div>
      </main>
    </div>
  )
}

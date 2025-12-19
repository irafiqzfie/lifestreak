import { Navigation } from "@/components/navigation"

export default function FriendsPage() {
  return (
    <div className="min-h-screen">
      <Navigation />
      <main className="container mx-auto px-4 py-8">
        <h1 className="text-3xl font-bold mb-6">Friends</h1>
        <div className="space-y-4">
          {/* TODO: Friends list component */}
          <div className="p-4 border rounded-lg">
            <p className="text-muted-foreground">Friends dashboard goes here</p>
          </div>
        </div>
      </main>
    </div>
  )
}

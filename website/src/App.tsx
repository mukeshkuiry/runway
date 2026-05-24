import './index.css'
import Navbar from './components/Navbar'
import ScrollProgress from './components/ScrollProgress'
import HeroSection from './components/HeroSection'
import DepartureBoardSection from './components/DepartureBoardSection'
import FlyoverSection from './components/FlyoverSection'
import WeatherSection from './components/WeatherSection'
import ATCSection from './components/ATCSection'
import InstallSection from './components/InstallSection'
import Footer from './components/Footer'

export default function App() {
  return (
    <div className="min-h-screen bg-runway-bg text-white">
      <ScrollProgress />
      <Navbar />
      <HeroSection />
      <DepartureBoardSection />
      <FlyoverSection />
      <WeatherSection />
      <ATCSection />
      <InstallSection />
      <Footer />
    </div>
  )
}

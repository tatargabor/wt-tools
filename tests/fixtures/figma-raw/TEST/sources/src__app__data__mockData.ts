export interface Product {
  id: number
  name: string
  shortDescription: string
  description: string
  price: number
  image: string
  category: string
  variants?: { [key: string]: string[] }
}

export interface Category {
  id: number
  name: string
  slug: string
}

export const products: Product[] = [
  {
    id: 1,
    name: "Wireless Earbuds Pro",
    shortDescription: "Premium sound, all-day comfort",
    description: "Experience crystal-clear audio with our flagship wireless earbuds.",
    price: 79.99,
    image: "/products/earbuds.jpg",
    category: "audio",
    variants: { color: ["Black", "White", "Navy"] },
  },
  {
    id: 2,
    name: "USB-C Hub 7-in-1",
    shortDescription: "Connect everything",
    description: "Expand your laptop connectivity with this premium hub.",
    price: 49.99,
    image: "/products/hub.jpg",
    category: "accessories",
  },
  {
    id: 3,
    name: "Mechanical Keyboard",
    shortDescription: "Precision typing experience",
    description: "Cherry MX switches with RGB backlighting.",
    price: 129.99,
    image: "/products/keyboard.jpg",
    category: "peripherals",
  },
]

export const categories: Category[] = [
  { id: 1, name: "Audio", slug: "audio" },
  { id: 2, name: "Accessories", slug: "accessories" },
  { id: 3, name: "Peripherals", slug: "peripherals" },
]

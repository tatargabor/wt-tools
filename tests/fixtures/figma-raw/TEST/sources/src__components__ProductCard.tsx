import { ShoppingBag } from 'lucide-react'
import Image from 'next/image'

interface ProductCardProps {
  product: Product
}

export function ProductCard({ product }: ProductCardProps) {
  return (
    <div className="flex flex-col gap-4 rounded-lg border p-4">
      <Image
        src={product.image}
        alt={product.name}
        className="w-full h-48 object-cover rounded-md"
      />
      <h3 className="text-lg font-semibold">{product.name}</h3>
      <p className="text-sm text-muted-foreground">{product.shortDescription}</p>
      <div className="flex items-center justify-between">
        <span className="text-xl font-bold">${product.price}</span>
        <button className="flex items-center gap-2">
          <ShoppingBag className="w-4 h-4" />
          Add to Cart
        </button>
      </div>
    </div>
  )
}

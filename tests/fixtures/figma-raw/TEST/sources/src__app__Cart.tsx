import { ShoppingBag, Trash2, Plus, Minus } from 'lucide-react'

interface CartItemProps {
  item: CartItem
  onRemove: (id: number) => void
  onUpdateQuantity: (id: number, qty: number) => void
}

export function CartItem({ item, onRemove, onUpdateQuantity }: CartItemProps) {
  return (
    <div className="flex items-center gap-4 border-b py-4">
      <img src={item.image} alt={item.name} className="w-16 h-16 rounded-md object-cover" />
      <div className="flex-1">
        <h4 className="font-medium">{item.name}</h4>
        <p className="text-sm text-muted-foreground">${item.price}</p>
      </div>
      <div className="flex items-center gap-2">
        <button onClick={() => onUpdateQuantity(item.id, item.quantity - 1)}>
          <Minus className="w-4 h-4" />
        </button>
        <span>{item.quantity}</span>
        <button onClick={() => onUpdateQuantity(item.id, item.quantity + 1)}>
          <Plus className="w-4 h-4" />
        </button>
      </div>
      <button onClick={() => onRemove(item.id)}>
        <Trash2 className="w-4 h-4 text-destructive" />
      </button>
    </div>
  )
}

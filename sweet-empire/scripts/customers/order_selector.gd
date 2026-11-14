class_name OrderSelector
extends RefCounted
# Extension point for stage-3 preferences; stage 2 uses equal weights only.
func weight(_product: ProductDefinition) -> float:
 return 1.0
func choose(available: Array[ProductDefinition], rng: RandomNumberGenerator) -> CustomerOrder:
 if available.is_empty(): return null
 var total: float = 0
 for product in available: total += maxf(0, weight(product))
 if total <= 0: return null
 var roll := rng.randf() * total
 for product in available:
  roll -= maxf(0, weight(product))
  if roll <= 0: return CustomerOrder.new(product.id)
 return CustomerOrder.new(available.back().id)

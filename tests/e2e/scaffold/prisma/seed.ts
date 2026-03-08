import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

async function main() {
  const products = [
    {
      name: "Laptop",
      description: "Nagy teljesítményű laptop munkához és játékhoz",
      price: 349990,
      stock: 15,
      imageUrl: "https://placehold.co/400x300?text=Laptop",
    },
    {
      name: "Gaming Egér",
      description: "Ergonomikus gaming egér RGB világítással",
      price: 12990,
      stock: 50,
      imageUrl: "https://placehold.co/400x300?text=Eg%C3%A9r",
    },
    {
      name: "Mechanikus Billentyűzet",
      description: "Cherry MX kapcsolós mechanikus billentyűzet",
      price: 24990,
      stock: 30,
      imageUrl: "https://placehold.co/400x300?text=Billenty%C5%B1zet",
    },
    {
      name: "Monitor",
      description: '27" 4K IPS monitor széles színskálával',
      price: 129990,
      stock: 10,
      imageUrl: "https://placehold.co/400x300?text=Monitor",
    },
    {
      name: "Webkamera",
      description: "1080p webkamera beépített mikrofonnal",
      price: 15990,
      stock: 40,
      imageUrl: "https://placehold.co/400x300?text=Webkamera",
    },
    {
      name: "USB-C Hub",
      description: "7-in-1 USB-C hub HDMI, USB 3.0, SD kártya",
      price: 8990,
      stock: 60,
      imageUrl: "https://placehold.co/400x300?text=USB-C+Hub",
    },
  ];

  for (const product of products) {
    await prisma.product.upsert({
      where: { id: products.indexOf(product) + 1 },
      update: product,
      create: product,
    });
  }

  console.log(`Seeded ${products.length} products`);
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (e) => {
    console.error(e);
    await prisma.$disconnect();
    process.exit(1);
  });

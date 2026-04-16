import { NextResponse } from "next/server";
import { listCurricula } from "@/lib/queries";

export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const curricula = await listCurricula();
    return NextResponse.json(curricula);
  } catch (e) {
    return NextResponse.json({ error: (e as Error).message }, { status: 500 });
  }
}

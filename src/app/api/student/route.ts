import { NextRequest, NextResponse } from "next/server";
import { getStudentByNickname } from "@/lib/queries";

export const dynamic = "force-dynamic";

export async function GET(req: NextRequest) {
  const nickname = req.nextUrl.searchParams.get("nickname");
  if (!nickname) {
    return NextResponse.json({ error: "nickname obrigatório" }, { status: 400 });
  }
  try {
    const student = await getStudentByNickname(nickname);
    if (!student) {
      return NextResponse.json({ error: "Aluno não encontrado" }, { status: 404 });
    }
    return NextResponse.json(student);
  } catch (e) {
    return NextResponse.json({ error: (e as Error).message }, { status: 500 });
  }
}

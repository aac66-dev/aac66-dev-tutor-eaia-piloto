-- ============================================================
-- AEP, Seed Rita. Gerado automaticamente por seed-rita.py.
-- Idempotente, pode ser re-corrido sem efeitos colaterais.
-- ============================================================

begin;

-- 1. Curriculum (Camada A)
insert into public.curricula (slug, title, education_level, source_url, version, notes)
values (
  'esa-enfermagem-veterinaria-2025', 'Licenciatura em Enfermagem Veterinária', 'ensino_superior_politecnico', 'https://www.ipcb.pt/esa', '2025-2026', 'Esqueleto preenchido a partir dos backups existentes do Assistente Rita 2. Completar tópicos e critérios com base no site oficial da ESA/IPCB.
'
)
on conflict (slug) do update set
  title = excluded.title,
  education_level = excluded.education_level,
  source_url = excluded.source_url,
  version = excluded.version,
  notes = excluded.notes;

-- 2. Units + Topics
with c as (select id from public.curricula where slug = 'esa-enfermagem-veterinaria-2025')
select 1;

-- Limpar units/topics anteriores deste curriculo para re-seed limpo.
delete from public.curriculum_units where curriculum_id = (select id from public.curricula where slug = 'esa-enfermagem-veterinaria-2025');

insert into public.curriculum_units (curriculum_id, code, title, period, ects, evaluation_criteria, order_index)
values (
  (select id from public.curricula where slug = 'esa-enfermagem-veterinaria-2025'),
  'ANAT1', 'Anatomia I', '1º Ano, 1º Semestre', 6, 'Preencher. Componente teórica (exame escrito) e componente prática (identificação anatómica).', 1
);

insert into public.curriculum_topics (unit_id, code, title, description, learning_objectives, order_index)
values (
  (select id from public.curriculum_units where code = 'ANAT1' and curriculum_id = (select id from public.curricula where slug = 'esa-enfermagem-veterinaria-2025')),
  'ANAT1-T1', 'Sistema esquelético, generalidades', null, 'Identificar ossos do esqueleto axial e apendicular, nomear acidentes ósseos.', 1
);

insert into public.curriculum_topics (unit_id, code, title, description, learning_objectives, order_index)
values (
  (select id from public.curriculum_units where code = 'ANAT1' and curriculum_id = (select id from public.curricula where slug = 'esa-enfermagem-veterinaria-2025')),
  'ANAT1-T2', 'Sistema muscular, generalidades', null, 'Descrever a classificação dos músculos e os principais grupos musculares.', 2
);

insert into public.curriculum_units (curriculum_id, code, title, period, ects, evaluation_criteria, order_index)
values (
  (select id from public.curricula where slug = 'esa-enfermagem-veterinaria-2025'),
  'BIOL1', 'Biologia Celular', '1º Ano, 1º Semestre', 5, 'Preencher.', 2
);

insert into public.curriculum_units (curriculum_id, code, title, period, ects, evaluation_criteria, order_index)
values (
  (select id from public.curricula where slug = 'esa-enfermagem-veterinaria-2025'),
  'QUIM1', 'Química Geral', '1º Ano, 1º Semestre', 5, 'Preencher.', 3
);

insert into public.curriculum_units (curriculum_id, code, title, period, ects, evaluation_criteria, order_index)
values (
  (select id from public.curricula where slug = 'esa-enfermagem-veterinaria-2025'),
  'ANAT2', 'Anatomia II', '1º Ano, 2º Semestre', 6, 'Avaliação mista. Exame teórico sobre miologia, artrologia e esplancnologia, com componente prática de identificação.', 4
);

insert into public.curriculum_topics (unit_id, code, title, description, learning_objectives, order_index)
values (
  (select id from public.curriculum_units where code = 'ANAT2' and curriculum_id = (select id from public.curricula where slug = 'esa-enfermagem-veterinaria-2025')),
  'ANAT2-T1', 'Cintura e membro pélvico', null, 'Descrever a cintura pélvica, identificar ossos, articulações e músculos do membro posterior (glúteos superficial e profundo, bíceps femoral, semitendinoso, semimembranoso, quadríceps, ísquio-tibiais).', 1
);

insert into public.curriculum_topics (unit_id, code, title, description, learning_objectives, order_index)
values (
  (select id from public.curriculum_units where code = 'ANAT2' and curriculum_id = (select id from public.curricula where slug = 'esa-enfermagem-veterinaria-2025')),
  'ANAT2-T2', 'Cintura e membro torácico', null, 'Descrever a cintura escapular, identificar ossos, articulações e músculos do membro anterior.', 2
);

insert into public.curriculum_topics (unit_id, code, title, description, learning_objectives, order_index)
values (
  (select id from public.curriculum_units where code = 'ANAT2' and curriculum_id = (select id from public.curricula where slug = 'esa-enfermagem-veterinaria-2025')),
  'ANAT2-T3', 'Esplancnologia, aparelho digestivo', null, 'Descrever os órgãos do tubo digestivo e glândulas anexas em espécies domésticas relevantes.', 3
);

insert into public.curriculum_topics (unit_id, code, title, description, learning_objectives, order_index)
values (
  (select id from public.curriculum_units where code = 'ANAT2' and curriculum_id = (select id from public.curricula where slug = 'esa-enfermagem-veterinaria-2025')),
  'ANAT2-T4', 'Esplancnologia, aparelho respiratório', null, 'Descrever vias aéreas superiores e inferiores, pulmões e pleura.', 4
);

insert into public.curriculum_units (curriculum_id, code, title, period, ects, evaluation_criteria, order_index)
values (
  (select id from public.curricula where slug = 'esa-enfermagem-veterinaria-2025'),
  'FISIO1', 'Fisiologia Animal', '1º Ano, 2º Semestre', 6, 'Preencher.', 5
);

insert into public.curriculum_units (curriculum_id, code, title, period, ects, evaluation_criteria, order_index)
values (
  (select id from public.curricula where slug = 'esa-enfermagem-veterinaria-2025'),
  'MICRO1', 'Microbiologia', '1º Ano, 2º Semestre', 5, 'Preencher.', 6
);

-- 3. Student Rita (insere apenas se ainda nao existir)
insert into public.students (full_name, nickname, education_level, institution, current_period, notes)
select
  'Rita Bettencourt Afonso', 'Rita', 'ensino_superior_politecnico', 'Escola Superior Agrária de Castelo Branco, IPCB', '1o Ano, 2o Semestre', 'Piloto 1 do AEP, importada do Assistente Rita 2.'
where not exists (
  select 1 from public.students where full_name = 'Rita Bettencourt Afonso'
);

-- 4. Enrollment Rita <-> curriculo ESA
insert into public.student_enrollments (student_id, curriculum_id, active, start_date)
select s.id, c.id, true, '2025-09-15'
from public.students s, public.curricula c
where s.full_name = 'Rita Bettencourt Afonso' and c.slug = 'esa-enfermagem-veterinaria-2025'
and not exists (
  select 1 from public.student_enrollments e
  where e.student_id = s.id and e.curriculum_id = c.id
);

-- 5. Sessoes legadas (aulas) importadas do backup JSON
-- Apaga importacoes anteriores para re-seed limpo:
delete from public.sessions where student_id = (select id from public.students where full_name = 'Rita Bettencourt Afonso')
  and notes like 'Legado: %';

insert into public.sessions (student_id, unit_id, topic_id, session_type, session_date, session_time, title, notes)
values (
  (select id from public.students where full_name = 'Rita Bettencourt Afonso'),
  (select u.id from public.curriculum_units u join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Anatomia II') limit 1),
  (select t.id from public.curriculum_topics t join public.curriculum_units u on u.id = t.unit_id join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Anatomia II') and lower(t.title) like lower('%Anexos musculares%') limit 1),
  'aula',
  '2026-02-25',
  '11:00',
  'Anexos musculares',
  'Legado: aula-anatomia-ii-anexos-musculares-2026-02-25.json
Avaliacao: 15 Abril
Ficheiros anexos: T2-INTROD. MIOLOGIA.pdf, T3-MIOLOGIA I.pdf

Tendões e aponevroses 
Fáscias 
Anexos sinoviais

Tendões:
Estrutura resistente 
Cilíndrica ou achatado
Nas extremidades do corpo do musculo
Resistência e elasticidade 
Inserção dos músculos no esqueleto 
Colagénio e tecido elástico
Fibrócitos 
Junção mio-tendinosa (entre o musculo e o tendão) 
Inserção no periósteo- porção mais externa do osso 
Tecido hialino, fibro-cartilaginoso (osso sesamoide)

Aponevroses:
Lamina fibrosa achatada 
Finas camadas de fibras tendinosas sobrepostas
Ex: músculos da parede abdominal 

Aponevroses de inserção
“Tendões” largos e finos
Inserções de músculos planos

Aponevroses de revestimento
Protege e contem o musculo 

Tendões:
Músculos longos 
Espessura concentrada 
Músculos fusiformes
Formato cilíndrico 

Aponevroses:
Músculos planos 
Distribuição de força em área
Músculos abdominais 
Formato lâmina 
Revestimento 

Interseção tendinosa 
Lâmina 
Impede o musculo de esticar muito
Resistência do musculo
Estão entre as fibras musculares 
Inserção de origem- mais fixa, menos movimento, é proximal
Inserção de terminação- porção com mais movimento, mais flexível, protege durante a tração

Direta- fibras em contacto direto
Indiretas- entre o musculo e o osso

Fáscias:
Membrana fibrosa
“Afina” contrações musculares, o musculo contrai ao mesmo tempo
Estão nos membros 
Braço- fáscia branquial (no úmero) e antebraquial (mais forte, menos flexível, no radio e ulna)

Fáscias toracolombares:
Dos membros pélvicos há região torácicas
Impulsiona o tronco 
Estabilidade- suporte da coluna
Conexão

Sinoviais (bainha e bolsas):
Por baixo de estruturas
Favorecem o deslizamento 
Evitam atritos entre o tendão e o osso
A bainha envolve o tendão
A bolsa fica entre 2 estruturas (tendão e osso, parecem almofadinhas) 

Funções dos músculos:
Ação motora (movimento)
Musculo Agonista (sinergia), Musculo Antagonista (oposição, faz o oposto do  musculo agonista)
Sinergia funcional (musculo principal)
Contrações isométricas, isotónicas e isocinéticas

Musculo agonista faz força (uns são extensores e outros são flexores) e o musculo antagonista contraria (ou faz o oposto).
Sinergia funcional tem um musculo principal que vai fazer a atividade principal e os outros músculos vão ajudar na mesma função.

Grupos funcionais:
Flexores
Extensores
Adutores
Abdutores

Tipos de movimentos
Alavanca classe 1- movimento interfixo, movimentos extensores.
Alavanca classe 2- movimento inter-resistente, muita força, amplitude reduzida.
Alavanca classe 3- movimentos interpotente, movimentos flexores, força limitada, grande amplitude.

Músculos da cabeça:
Músculos cutâneo facial:
Músculo cutâneo facial
Músculo cutâneo dos lábios
Músculo cutâneo frontal
Músculo cutâneo nasal

Nervo facial:
Artérias labiais, nasais e artéria palatina

Platysma- musculo que liga a cabeça com o pescoço.

Musculo cutâneo frontal- inserção de origem e de terminação sobre o osso frontal e o temporal. Função- fixa a cartilagem da orelha rostralmente. 

Músculos da face:
Elevador naso-lateral
Malar
Zigomático
Elevador do lábio superior
Canino 
Bucinador
Depressor do lábio inferior'
);

insert into public.sessions (student_id, unit_id, topic_id, session_type, session_date, session_time, title, notes)
values (
  (select id from public.students where full_name = 'Rita Bettencourt Afonso'),
  (select u.id from public.curriculum_units u join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Anatomia II') limit 1),
  (select t.id from public.curriculum_topics t join public.curriculum_units u on u.id = t.unit_id join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Anatomia II') and lower(t.title) like lower('%cintura e membro pélvico%') limit 1),
  'aula',
  '2026-04-01',
  '11:00',
  'cintura e membro pélvico',
  'Legado: aula-anatomia-ii-cintura-e-membro-pélvico-2026-04-01.json
Avaliacao: 15 abril
Ficheiros anexos: T6-MIOLOGIAIV.pdf

Glúteo superficial:
Inserção de origem- tuberosidade coxal
Inserção de terminação- tuberosidade glútea o terceiro trocânter 
Função- abdutor da coxa e rotação

Gluteobiceps 

Bíceps femoral:
Inserção de origem- tuberosidade isquiática (lateralmente) 
Inserção de terminação- crista e face medial da tíbia 
Função- flexão da perna

Glúteo medio:
Inserção de origem- asa do ílio 
Inserção de terminação- grande trocânter do fémur
Função- extensor da coxa

Glúteo acessório:
Inserção de origem- asa do ílio 
Inserção de terminação- grande ou 3 trocanter do fémur 
Função- abdução e rotação da coxa

Tensor da coxa: 
Tensor da fáscia lata:
Inserção de origem- tuberosidade coxal
Inserção de terminação- fáscia lata (sobre a patela)
Função- flexão da coxa e extensão da perna

Quadríceps femoris:
4 cabeças- reto femural, vasto lateral, vasto intermedio e vastomedial.
Função- potente extensor da perna

Rectus femoris:
Inserção de origem- corpo do ílio
Função de terminação- patela

Smitendinoso:
Inserção de origem- tuberosidade isquiática
Inserção de terminação- tíbia
Função- extensão da coxa e flexão da perna'
);

insert into public.sessions (student_id, unit_id, topic_id, session_type, session_date, session_time, title, notes)
values (
  (select id from public.students where full_name = 'Rita Bettencourt Afonso'),
  (select u.id from public.curriculum_units u join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Anatomia II') limit 1),
  (select t.id from public.curriculum_topics t join public.curriculum_units u on u.id = t.unit_id join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Anatomia II') and lower(t.title) like lower('%Membro torácico%') limit 1),
  'aula',
  '2026-03-11',
  '11:00',
  'Membro torácico',
  'Legado: aula-anatomia-ii-membro-torácico-2026-03-11.json
Avaliacao: 15 abril
Ficheiros anexos: T4-MIOLOGIAII.pdf

Espádua 
Braço
Antebraço

Lateralmente- músculos extensores e abdutores
Medialmente- músculos flexores e adutores

Região escapular lateral:
- deltoide
- supraespinhoso
- infraespinhoso
- pequeno redondo

Deltoide:
Inserção de origem: escapular
Inserção de terminação: úmero
Função: principal abdutor do braço

Supraespinhoso:
Inserção de origem: fossa infraespinhosa
Inserção de terminação: úmero
Função: abdução do braço

Subescapular:
Inserção de origem: Fossa subescapular
Inserção de terminação: tubérculo menor do úmero 
Função:  Adutor do braço

Grande redondo:
Inserção de origem: escapula
Inserção de terminação: tuberosidade do grande redondo
Função: adutor do braço

Coracobraquial:
Inserção de origem: processo caracóide da escapula
Inserção de terminação: úmero (face medial)
Função: adutor do braço

Região braquial (cranial e caudal):
Região cranial- bíceps braquial, braquial.'
);

insert into public.sessions (student_id, unit_id, topic_id, session_type, session_date, session_time, title, notes)
values (
  (select id from public.students where full_name = 'Rita Bettencourt Afonso'),
  (select u.id from public.curriculum_units u join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Anatomia II') limit 1),
  (select t.id from public.curriculum_topics t join public.curriculum_units u on u.id = t.unit_id join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Anatomia II') and lower(t.title) like lower('%Miologia%') limit 1),
  'aula',
  '2026-02-18',
  '11:00',
  'Miologia',
  'Legado: aula-anatomia-ii-miologia-2026-02-18.json
Avaliacao: 22 abril
Ficheiros anexos: T2-INTROD. MIOLOGIA.pdf

Miologia- Parte da organografia que estuda os músculos e os músculos e seus anexos
Musculos- Órgãos ativos do movimento
Caracteristicas.
Contractabilidade
Excitabilidade
Extensibilidade
Elasticidade 

Tipos de músculos:
Musculo liso (vísceras, involuntário)
Musculo cardíaco (estriado, involuntário)
Musculo esquelético (estriado, voluntario)

Não vamos estudar os músculos lisos
Musculo esquelético, volutario- células cilíndricas muito longas são as fibras musculares

Formam grupos delimitados pelas fascias, realizam a mesma função

Classificação:
Inserção no esqueleto 
Locomoção, termorregulação
Modelam as regiões corporais
Tendões, aponevroses, bainhas sinoviais
Medidas e índices zoometricos 
Carne de elevado valor comercial
Proporção na carcaça variável com a idade

So há músculos impares o resto são pares
Musculos cutâneos- movimentos da pele, sem ligação ao esqueleto

Localização (plano mediano)
Impares (simétricos) ex: anus
Pares (assimétricos)

Forma:
Longos (membros)
Planos (tronco)
Curtos (coluna vertebral ou numa articulação)

Inserção origem 

Musculos Longos
Disposição das fibras musculares:
M. Unpennatus (penado) forma de meia pena
M. Bipennatus, forma de pena
M. Multipennatus, forma de varias penas a confluírem para o mesmo tendão

M. digástrico- 2 ventres unidos por 1 tendão 
M. poligástrico – vários ventres'
);

insert into public.sessions (student_id, unit_id, topic_id, session_type, session_date, session_time, title, notes)
values (
  (select id from public.students where full_name = 'Rita Bettencourt Afonso'),
  (select u.id from public.curriculum_units u join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Anatomia II') limit 1),
  (select t.id from public.curriculum_topics t join public.curriculum_units u on u.id = t.unit_id join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Anatomia II') and lower(t.title) like lower('%Miologia%') limit 1),
  'aula',
  '2026-02-19',
  '14:00',
  'Miologia',
  'Legado: aula-anatomia-ii-miologia-2026-02-19.json
Avaliacao: 15 abril
Ficheiros anexos: T2-INTROD. MIOLOGIA.pdf

Lamina e cabo de bisturi
Tesoura de Mayo, pode ser reta ou curva, com as pontas retas ou rombas ou ambas
Custotumo corta costelas
Pinça anatómica de bico de pato, causa menos danos nos tecidos mas segura menos
Pinça anatómica dente de rato
Pinça emostatica de Koker, faz preensão 
Afastadores
Sonda de butterfly

Fascia da tíbia é a fáscia cruris
Fascia Branquial e Fascia ante branqueal
Duvida em relaçãoas fascias no geral

Inserção de Origem, “onde começa o musculo”
Inserção de Terminação, “onde termina o musculo”
Função do musculo

Biceps Femural- 2 cabeças
Triceps Branqueal- 3 cabeças – 1longa que se insere na escapula, 1lateral que se insere no úmero e 1medial que se insere no úmero, 1terminação no oleocraneo da ulna

Gemeos 2 inserções origem no fémur 1 inserção de terminação no calcâneo

Musculo extensor ulnar do carpo
Musculo Extensor lateral dos dedos

Gluteo bicps so existe nos bovinos, junção do bíceps femural.'
);

insert into public.sessions (student_id, unit_id, topic_id, session_type, session_date, session_time, title, notes)
values (
  (select id from public.students where full_name = 'Rita Bettencourt Afonso'),
  (select u.id from public.curriculum_units u join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Anatomia II') limit 1),
  (select t.id from public.curriculum_topics t join public.curriculum_units u on u.id = t.unit_id join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Anatomia II') and lower(t.title) like lower('%miologia%') limit 1),
  'aula',
  '2026-02-26',
  '14:00',
  'miologia',
  'Legado: aula-anatomia-ii-miologia-2026-02-26.json
Avaliacao: 15 Abril
Ficheiros anexos: T3-MIOLOGIA I.pdf

Canino 
Inserção de origem: bordo caudal da fossa canica
Inserção de terminação: nariz e lábio superior
Função: deslocação lateral do lábio superior, nos ruminantes e nos suínos desloca o lábio superior para baixo

Músculos da face:
Incisivo
Mentoniano
Orbicularis oris
Orbicularis oculi
Nasais

Orbicularis oris- 2 porções, não tem inserção óssea, insere-se na face profunda da pele ou da mucosa labial, participa na preensão e na sucção.

Orbicularis oculi- mais fino que o oris, 2 porções, inserção de origem no tendão sobre o osso lacrimal, inserção de terminação na inserção de fascículos carnudos na face profunda da pele e tem como função fechar as pálpebras.

Região dos músculos mastigadores:
Masséter- esta na parte lateral, parte de bora da mandíbula
Temporal
Digástrico
Pterigoideu medial- na parte de dentro da mandibula
Pterigoideu lateral- na parte de dentro da mandibula

Masséter:
Porção superficial e porção profunda
Inserção de origem- arcada zigomática, crista e tuberosidade facial
Inserção de terminação- fossa massetérica e bordo caudal de ângulo da mândibula
Função- aproximação da mandibula e maxilar, responsável por fechar a boca.

Temporal
Inserção de origem- lâmina profunda da fáscia temporal
Inserção de terminação- lâmina tendinosa
Função- eleva a mandibula, fecha a boca.

Pterigoide medial
Inserção de origem- sobre a crista pterigo-palatina
Inserção de terminação- fossa pterigoide do ramo da mandibula
Função- eleva a mandibula, fecha a boca

Pterigoide lateral
Inserção de origem- face ventral do esfenoide 
Inserção de terminação- fóvea pterigoide do colo da mandibula
Função- desloca a mandibula em direção rostral (protração)

Digástrico 
Inserção de origem- processo paracondilar, apex do processo jugular
Inserção de terminação- face medialda parte molar da mandibula, próximo ao bordo ventral
Função- baixa a mandibula, abre a boca

Região dos músculos hioideus 
Omo-Hioideu
Milo-Hioideu
Genio-Hioideu
Occipito-Hioideu
Estilo-Hioideu
Cerato-Hioideu
Transverso do Hioide

Milo
Inserção de origem- linha milo-hioidea
Inserção de terminação- rafe fibrosa e processo lingual do hioide
Função- desloca o hioide em direção rostral e dorsal

Genio 
Inserção de origem- superfície geniana da mandibula
Inserção de terminação- processo lingual do hioide 
Função- desloca o hioide em direção rostral (protrator)

Estilo 
Inserção de origem- extremidade proximal do estilohioide
Inserção de terminação- base do tirohioide
Função- é retrator, põem a língua para dentro, antagonista do genio-hioideu

Região auricular
Auriculares rostrais:
Fornto- escapular
Zigomático- auricular
Zigomático- escutular
Escutulo- auriculares superficiais
Escutulo- auriculares profundos

Auriculares dorsais:
Interescutular
Parieto- escutular
Parieto-auricular

Auriculares caudais:
Cervico- auriculares, superficial, medio e profundo
Cervico- escutular

Auricular ventral
Parotídeoauricular (faz com que a orelha baixe)
Inserção de origem- fáscia cervicalis
Inserção de terminação- antitragos
Função- inclinação caudal da orelha'
);

insert into public.sessions (student_id, unit_id, topic_id, session_type, session_date, session_time, title, notes)
values (
  (select id from public.students where full_name = 'Rita Bettencourt Afonso'),
  (select u.id from public.curriculum_units u join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Anatomia II') limit 1),
  (select t.id from public.curriculum_topics t join public.curriculum_units u on u.id = t.unit_id join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Anatomia II') and lower(t.title) like lower('%musculos do tronco%') limit 1),
  'aula',
  '2026-03-18',
  '11:00',
  'musculos do tronco',
  'Legado: aula-anatomia-ii-musculos-do-tronco-2026-03-18.json
Avaliacao: 15 abril

Musculo grande dorsal:
Inserção de origem: ligamento supraespinhoso
Inserção de terminação: face medial do úmero
Função: puxa o membro caudalmente e propulsiona o tronco para a frente

Romboide torácico:
Inserção de origem: ligamento supraespinhosoe ápice dos processos espinhosos torácicos.
Inserção de terminação: bordo dorsal, face medial da escapula e cartilagem escapular
Função: puxa a escápula contra as vertebras

Musculo dentado ventral torácico:
Inserção de origem: face lateral das costelas
Inserção de terminação: face serrata da escapula

Musculo dentado dorsal cranial
Musculo dentado dorsal caudal

Musculo erector spinae
Musculo iliocostal
Musculo longíssimos 
Musculo espinhoso 

Iliocostal torácico
Inserção de origem: crista ilíaca
Inserção de terminação: angulo costal de cada costela
Função: fixação da região lombar e das costelas

Iliocostal cervical:
Inserção de origem: crista iliaca
Inserção de terminação: processos transversos cervicais
Função: fixação da região lombar e das vertebras cervicais

Muculo longíssimos torácicos:
Inserção de origem: apófises espinhosas e transversos das vertebras torácicas 
Inserção de terminação: tubérculo costal
Função: fixação e extensão da coluna vertebral, elevação da cabeça e reflexão lateral do pescoço


Musculo longissimus cervical
Musculo longissimus atlantis
Musculo longissimus cefálico

Musculo erector spinae:
musculo espinhoso do torax
Inserção de origem e inserção terminação: apófises espinhosas das vertebras torácicas
Função: fixa o dorso e pescoço 

Músculos da parede torácica
Musculo dentado dorsal cranial'
);

insert into public.sessions (student_id, unit_id, topic_id, session_type, session_date, session_time, title, notes)
values (
  (select id from public.students where full_name = 'Rita Bettencourt Afonso'),
  (select u.id from public.curriculum_units u join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Anatomia II') limit 1),
  (select t.id from public.curriculum_topics t join public.curriculum_units u on u.id = t.unit_id join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Anatomia II') and lower(t.title) like lower('%Músculos abdominais%') limit 1),
  'aula',
  '2026-03-25',
  '11:00',
  'Músculos abdominais',
  'Legado: aula-anatomia-ii-músculos-abdominais-2026-03-25.json
Avaliacao: 15 abril
Ficheiros anexos: T5-MIOLOGIAIII.pdf

Musculo obliquo externo do abdómen:
Tem uma parte carnuda, tem fascículos, uma aponevrose ventro-caudal.
Inserção de origem- costelas e torax
Inserção de terminação- ilio e aponevroses 
Função- sustentação e compreensão das vísceras abdominais, contribuindo na inspiração e flexão da coluna vertebral

Musculo obliquo interno abdómen:
Vai do ilio até a virilha, anel inguinal profundo, musculo cremáster, responsável pela elevação dos testículos nos machos
Função- sinergia com o musculo obliquo esterno do abdómen


Musculo reto do abdómen:
Musculo poligástrico 
Inserção de origem- cartilagens costais 
Inserção de terminação- pubis
Função- eleva e comprime as vísceras abdominais desloca as costelas em direção caudal, ajuda na inspiração.

Musculo transverso do abdómen:
Inserção de origem- nas últimas costelas
Inserção de terminação- processo xifoide 
Função- encerra o abdomen'
);

insert into public.sessions (student_id, unit_id, topic_id, session_type, session_date, session_time, title, notes)
values (
  (select id from public.students where full_name = 'Rita Bettencourt Afonso'),
  (select u.id from public.curriculum_units u join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Anatomia II') limit 1),
  (select t.id from public.curriculum_topics t join public.curriculum_units u on u.id = t.unit_id join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Anatomia II') and lower(t.title) like lower('%músculos do pescoço%') limit 1),
  'aula',
  '2026-03-04',
  '11:00',
  'músculos do pescoço',
  'Legado: aula-anatomia-ii-músculos-do-pescoço-2026-03-04.json
Avaliacao: 15 abril
Ficheiros anexos: T3-MIOLOGIA I.pdf

Grupos musculares  
Região cervical dorsal
Região cervical ventral
Justavertebrais 

Músculos do pescoço estão separados pelo ligamento nucal e são músculos pares e planos, mais finas e mais largos sobrepostos em 4 camadas.

1ª camada- trapézio, omotransverso
2ª camada- rombóide, dentado
3ª camada- esplénio 
4ª camada- smi-espinhoso da cabeça longissimus do atlas

Trapézio:
Porção cervical:
Inserção de origem: rafe fibrosa
Porção torácica:
Inserção de origem: ligamento supreespinhoso e processo espinhoso das vertebras torácicas
Inserção de terminação: espinha da escapula
Função: fixação, elevação e rotação da escapula

Romboide:
Porção cervical:
Inserção de origem: corda do ligamento nucal
Porção torácica:
Inserção de origem: ligamento supraespinhoso e processos espinhosos das vertebras torácicas
Inserção de terminação: margem dorsal da escapula e cartilagem escapular 
Função: fixação da escapula, elevação e retração do membro torácico, elevação e extensão do pescoço.

Dentado do pescoço:
Inserção de origem: processos transversos das vertebras cervicais superfície do torax em suínos e ruminante.
Inserção de terminação: ângulo cranial 
Função: fixação da escapula, puxa a escapulo para baixo e para a frente adutor do membro'
);

insert into public.sessions (student_id, unit_id, topic_id, session_type, session_date, session_time, title, notes)
values (
  (select id from public.students where full_name = 'Rita Bettencourt Afonso'),
  (select u.id from public.curriculum_units u join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Fisiologia II') limit 1),
  (select t.id from public.curriculum_topics t join public.curriculum_units u on u.id = t.unit_id join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Fisiologia II') and lower(t.title) like lower('%Absorção do aparelho digestivo%') limit 1),
  'aula',
  '2026-02-24',
  '14:00',
  'Absorção do aparelho digestivo',
  'Legado: aula-fisiologia-ii-absorção-do-aparelho-digestivo-2026-02-24.json

1
Nutriente: Hidratos
Digestão enzimática: Amílase proteica e dissacarídeos
Absorção: Monossacarídeos 

2
Nutriente: Proteínas 
Digestão enzimática: Tripsine e peptidases 
Absorção: Aminoacidos e peptídeos 

3
Nutriente: Lípidos
Digestão enzimática: Bílis (emulsão) e lípase
Absorção: Ácidos gordos, micelas 

O intestino faz a fermentação de hidratos de carbono e proteínas.

No intestino grosso- colon (não há digestão)
Absorção- Recuperação de água e eletrólitos, transformando o quilo em fezes sólidas.
Fermentação- Produção de AGCC (Ácidos Gordos de Cadeia Curta), como o acetato, propionato e butirato a partir da fibra.
Síntese- Produção microbiana de vitamina K e vitaminas do complexo B.

Motilidade Gatrointestinal
Peristaltismo- ondas propulsivas que empurram o conteúdo ao longo do trato.
Segmentação- contrações rítmicas de mistura para otimizar a digestão.
CMM (Complexo Migratório Mioelétrico)-  a “vassoura” do intestino que limpa resíduos durante o jejum.

Suínos- omnívoros com analise salivar significativa e divertículo gástrico. 
Equino- herbívoros com fermentação cecal e cólica por excesso de amido.
Coelho- cecotrofia- ingestão de fezes noturnas ricas em nutrientes.'
);

insert into public.sessions (student_id, unit_id, topic_id, session_type, session_date, session_time, title, notes)
values (
  (select id from public.students where full_name = 'Rita Bettencourt Afonso'),
  (select u.id from public.curriculum_units u join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Fisiologia II') limit 1),
  (select t.id from public.curriculum_topics t join public.curriculum_units u on u.id = t.unit_id join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Fisiologia II') and lower(t.title) like lower('%aparelho digestivo%') limit 1),
  'aula',
  '2026-02-24',
  '11:00',
  'aparelho digestivo',
  'Legado: aula-fisiologia-ii-aparelho-digestivo-2026-02-24.json

Para que serve o sistema digestivo? Para absorção de nutrientes (sais minerais, vitaminas, proteínas, etc).
O sistema digestivo é exterior, ou seja, os alimentos não vão para a corrente sanguínea.
Os órgãos do aparelho digestivo:
Boca- glândulas salivares, língua, dentes
Faringe- orofaringe- movimentos peristálticos
Estomago
Intestino delgado
Intestino grosso
Reto e ânus 

A língua serve para mexer os alimentos dentro da boca e para sentir o sabor dos alimentos onde estão 90% das papilas gustativas, o sabor é uma sensação.
Saliva- secreção das glândulas salivares para fazer o bolo alimentar.
A absorção do amido termina no estomago.
Monogástricos- cão, gato, humano, porco, cavalo (só têm um estomago sem comparrimentos).
Mucina- protege
Quimo- é como se fosse o bolo alimentar só que no estomago, é uma mistura.
A digestão começa na boca e termina no intestino grosso.
Piloro- válvula do fim do estomago 

Camadas- mucosa, submucosa, muscular e serosa.

Sistema entérico 
Autónomo- controlo simpático e parassimpático

Preensão e mastigação
A digestão começa com a redução mecânica das partículas e mistura com a saliva 
Saliva- lubrificação (mucina) e tampão, secreções serosas.
Esófago- transporte via peristaltismo primário e secundário.
Morfologia
Regiões- cabeça, fundo, corpo e antro piloro.
Armazenamento temporário e barreira de muco/bicarbonato 
Passagem lenta de quimo ao ID

Secreção acida 
Células parietais- produzem HCI e fator intrínseco (vitamina B12)
Células principais- pepsinogenio para digestão proteica, convertido em pepsina pelo HCL.
Glândulas anexas- fígado e pâncreas 
Suco intestinal- lípase intestinal, amilase intestina, peptiase 
Bilis- emulsificação
Suco pancreático- amalise pancreática, lípase pancreática, tripsina e quimiotripsina , iões bocarbonato (pH8).'
);

insert into public.sessions (student_id, unit_id, topic_id, session_type, session_date, session_time, title, notes)
values (
  (select id from public.students where full_name = 'Rita Bettencourt Afonso'),
  (select u.id from public.curriculum_units u join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Fisiologia II') limit 1),
  (select t.id from public.curriculum_topics t join public.curriculum_units u on u.id = t.unit_id join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Fisiologia II') and lower(t.title) like lower('%dor%') limit 1),
  'aula',
  '2026-03-24',
  '11:00',
  'dor',
  'Legado: aula-fisiologia-ii-dor-2026-03-24.json

Dor- experiencia sensorial e emocional desagradável, associada a dano tecidual real ou potencial.
Dor 0 é patológico

Sinal de proteção- função evolutiva para evitar danos adicionais (parte “boa” da dor) 
Impacto destrutivo- comprometimento do bem-estar e atraso na recuperação fisiológica (parte “má” da dor) 

A dor pode ter um impacto destrutivo fisicamente e emocionalmente
A dor é o 5º sinal vital

Matriz de tipos de dor:
Dor crónica- permanece mais de 3 meses no mesmo local, não tem função protetora, é uma doença em si, por exemplo, dor oncológica, e osteoartrite, esta dor persiste além da cicatrização.
Dor aguda- aparecimento súbito, duração limitada, tem função protetora, por exemplo, cirurgias e trauma.
Dor inflamatória- associada a dor nos tecidos, lesão tecidual continua e resposta imunitária, é uma dor parcialmente protetora, por exemplo, pós-operatório e infeções.
Dor neuropática- quando as terminações nervosas estão afetadas, lesão neural central ou periférica, não tem função protetora, por exemplo, amputações e hérnia discal.

Nocicepção- perceção da dor

Via de nocicepção (via ascendente)
2 vias, uma ascendente e uma descendente 
Tradução, estímulo novo (mecânico, térmico e químico). Avaliação de nocicepção de nociceptores periféricos: fibras A5 (rápidas) e fibras C (lentas)
Transmissão, o impulso viaja: nervo periférico vai para a medula espinal, depois vai para o tálamo e do tálamo para o córtex
Modulação, a interseção neuroquimica na medula. Mecanismos inibitórios endógenos atuam aqui (ex: vias descendentes serotoninergicas e noradrenergicas)
Percepção, o cérebro acende: a experiencia consciente e emocional da dor pelo animal

3 vias ativas- córtex: localização da dor memoria da dor e reação da dor.

Via da nocicepção (via descendente- analgesia):
Mesencéfalo- seratonina/noradrenalina
Ativação de interneuronios inibidores- opioides, encefalina GABA glicina
Bloqueio da sinapse do neurónio de 2ª ordem 
Bloqueio das vias ascendentes da dor

Neurotransmissores: glutamato, substância P, CGRP, prostaglandinas e citocinas 

Plasticidade neural:
Sensibilização periférica e central: o sistema nervoso aprende a dor
Hiperalgesia: resposta exagerada a um estímulo doloroso, X-X/2
Alodinia: dor causada por provocaria dor como por exemplo um toque leve. Delta e C-β'
);

insert into public.sessions (student_id, unit_id, topic_id, session_type, session_date, session_time, title, notes)
values (
  (select id from public.students where full_name = 'Rita Bettencourt Afonso'),
  (select u.id from public.curriculum_units u join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Fisiologia II') limit 1),
  (select t.id from public.curriculum_topics t join public.curriculum_units u on u.id = t.unit_id join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Fisiologia II') and lower(t.title) like lower('%Fisiologia Digestiva do Ruminante%') limit 1),
  'aula',
  '2026-03-03',
  '11:00',
  'Fisiologia Digestiva do Ruminante',
  'Legado: aula-fisiologia-ii-fisiologia-digestiva-do-ruminante-2026-03-03.json

Processo de ruminação- regurgitação, remastigação, resalivação e redeglutição permitem reprocessamento do alimento para otimizar digestão e absorção de nutrientes.
Simbiose microbiana- bactérias, protozoários e fungos no rúmen degradam celulose, permitindo nutrição através de relações simbióticas únicas entre hospedeiro e microrganismos.
Adaptação evolutiva- capacidade de digerir celulose viabilizou colonização de ambientes com baixa disponibilidade de alimentos de alta qualidade nutricional.
Definição característica- mamíferos herbívoros com estômago compartimentado (poligástricos) e sistema digestivo único, adaptado para processamento eficiente de alimentos fibrosos.

Não há possibilidade de haver digestão sem que haja a existência de bactérias na pança.

Os alimentos precisam de uma fermentação prévia através das bactérias.

Visão Geral do Sistema Digestivo:
Fase 1- Pré estomago (omaso):
Fermentação microbiana ocorre no rúmen, retículo e omaso, iniciando a degradação dos alimentos ingeridos pelos ruminantes (também absorve o excesso de agua).

Fase 2- Estomago verdadeiro (abomaso):
Digestão ácida e enzimática no abomaso processa o alimento fermentado, preparando-o para a absorção intestinal eficiente.

Fase 3- Intestino delgado:
Absorção de nutrientes e proteína microbiana ocorre, maximizando a disponibilidade de aminoácidos e energia para o animal.

Fase 4- Intestino grosso:
Absorção de água e eletrólitos finaliza o processo digestivo, consolidando fezes para eliminação adequada.

Feedback- Regulação contínua:
Mecanismos hormonais e neurológicos regulam continuamente todo o processo digestivo para otimizar eficiência nutricional.

Chave da aula- a proteína absorvida no intestino delgado de um ruminante provem maioritariamente da morte das bactérias da pança.

Estrutura dos pré estômagos:
Retículo (barrete):
Aspeto de favo de mel com volume 5 a 10 litros, local crítico de retenção de corpos estranhos metabolitos perigosos para ruminantes.

Rúmen (pança):
Maior compartimento com 100 a 200 litros, camara de fermentação anaeróbica mantendo temperatura entre 38 a 40 graus centígrados.

Omaso (folhoso):
Estrutura lamelar com volume 5 a 8 litros, realiza função essencial de desidratação do alimento.

O ruminante tem uma cuba de fermentação que o aquece por isso ele sofre de stress por calor mas não sofre de stress por frio, a própria fermentação feita pelas bactérias é que faz a termorregulação, 38,5 a 39,2 graus. Entram em stress térmico a partir dos 22 graus, eles não conseguem realizar perda de calor pela termorregulação, só conseguem perder calor com ajuda de fatores externos de arrefecimento como ventoinhas e etc…

Rúmen o coração da digestão:
Regulação- saliva alcalina:
Produção continua de saliva alcalina entre 5 a 15 litro diário desempenha função tampão essencial para estabilidade ruminal.

Ambiente anaeróbico:
Ambiente anaeróbico estável funciona como pré requisito essencial para desenvolvimento e manutenção da flora microbiana ruminal.

Condições ótimas- pH e temperatura:
pH ideal entre 6 a7 e temperatura constante de 38 a 40 graus criam condições fermentativas  ótimas  para microrganismos.

Estrutura- papilas ruminais:
Papilas ruminais aumentam significativamente a superfície da absorção de absorção de ácidos gordos voláteis em ate 1800 centímetros quadrados.

Função- motilidade ruminal:
Motilidade ruminal com contrações de ruminação realiza a mistura, propulsão e seleção eficiente de partículas.

Importante o ambiente ser anaeróbico essencial para desenvolvimento e manutenção da flora microbiana intestinal, produzem gases que saem pelo esófago (os gases são produto da fermentação, mas não são benéficos para o animal por isso são expulsos, gases como dióxido de carbono e metano).

Simbiose microrganismo-hospedeiro:
Flora ruminal:
10 elevado a 10 bactérias/Ml, 10 elevado a 6 protozoários/mL, fungos anaeróbicos formam comunidade dinâmica e complexa.

Beneficio microbiano:
Degradação de substrato complexo, síntese de proteína celular e produção de ácidos voláteis essenciais.

Beneficio do ruminante:
Acesso a energia de celulose, aminoácidos, vitaminas b e k e economia significativa de proteína dietética.

As vacas não devem comer a placenta porque a proteína da carne não é benéfica para elas, elas só comem para esconder a prova que pariram.'
);

insert into public.sessions (student_id, unit_id, topic_id, session_type, session_date, session_time, title, notes)
values (
  (select id from public.students where full_name = 'Rita Bettencourt Afonso'),
  (select u.id from public.curriculum_units u join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Fisiologia II') limit 1),
  (select t.id from public.curriculum_topics t join public.curriculum_units u on u.id = t.unit_id join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Fisiologia II') and lower(t.title) like lower('%Fisiologia Digestiva do Ruminante continuação da aula anterior%') limit 1),
  'aula',
  '2026-03-03',
  '14:00',
  'Fisiologia Digestiva do Ruminante continuação da aula anterior',
  'Legado: aula-fisiologia-ii-fisiologia-digestiva-do-ruminante-continuação-da-aula-anterior-2026-03-03.json

Fermentação microbiana:
Têm como objetivo produzem ácidos gordos voláteis no rumen (acetato).
Composição e funções dos ácidos gordos voláteis. 
O acetato tem como objetivo produzir energia e glicose (60% a 70% são usados) e para gordura do leite.
Propionato faz a gliconeogénese (nova formação de glicose) no fígado (15% a 20%).
Butirato usa 5% a 10% para producir energía epitedial ruminal.

Degradação proteica e síntese microbiana:
Proteólise, proteína dietética é convertida em proteínas e aminoácidos pelas enzimas microbianas do rumen.
Desaminação, aminoácidos sofrem disaminação libertando amonia e cetoácidos essenciais para síntese microbiana.
Síntese proteica microbiana, amonia cetoácidos e energia dos ácidos gordos voláteis formam proteína microbiana de alta qualidade.
Passagem e absorção, proteína microbiana segue para o abomaso e intestino delgado para digestão e absorção de aminoácidos.
Sincronização energia proteica, a eficiência do processo depende da sincronização adequada entre a disponibilidade de energia e proteína no rúmen. 

Síntese de vitaminas e cofatores:
Vitaminas di complexo B, são sintetizadas pelos microrganismos ruminantes.
Vitaminas K, produzidas pelas bactérias anaeróbicas, essenciais para o processo de coagulação sanguínea dos ruminantes.
Independência nutricional, ruminantes não necessitam ingerir vitaminas B e K exogenamente porque são sintetizadas endogenamente pelos microrganismos ruminais.
Implicações clínicas, antibióticos que suprimem a fibra ruminal podem provocar deficiências vitamínicas secundarias graves nos ruminantes.

Eructação- saída de gases pelo esófago (eliminação de gases), sistema nervoso parassimpático, mecanismo fisiológico.

Sinais de alerta- ausência de eructação, morre de asfixia pelos gases que não são eliminados, ou pode nem estar a produzir gases.'
);

insert into public.sessions (student_id, unit_id, topic_id, session_type, session_date, session_time, title, notes)
values (
  (select id from public.students where full_name = 'Rita Bettencourt Afonso'),
  (select u.id from public.curriculum_units u join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Fisiologia II') limit 1),
  (select t.id from public.curriculum_topics t join public.curriculum_units u on u.id = t.unit_id join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Fisiologia II') and lower(t.title) like lower('%olho%') limit 1),
  'aula',
  '2026-03-17',
  '11:00',
  'olho',
  'Legado: aula-fisiologia-ii-olho-2026-03-17.json

Esclerótica: 
Camada fibrosa densa
Locais de perfuração vascular/ nervo otico
Espassamentos- músculos
Limbo esclero-corneal 

Úvea:
Iris (duas facetas, anterior e posterior, duas circunferências, uma maior e uma menor, pupila)
Zona ciliar (circulo ciliar, processos ciliares)
Corode (nutrição da retina, hemisfério posterior)

Cristalino:
Lente biconvexa
Transparente
Concentração dos raios luminosos
Caudalmente á iris e medialmente ao processo ciliar

Humor aquoso:
Camara anterior
Camara posterior
Um liquido no interior que é um gel

Retina: permite a visão a cores, expansão terminal do nervo otico, camada profunda do globo ocular, porção iridociliar, porção nervosa, papila otica.

Retina:
1-	Córnea
2-	Iris
3-	Pupila
4-	Cristalino
5-	Conjuntiva
6-	Retina
7-	Nervo otico


Cruzamento das vias nervosas no quiasma ótico.

Campo visual
Retina
Nervo ótico
Quiasma ótico 
Trato óticos
Sinais óticos


Músculos:
Recto medial
Recto lateral
Recto dorsal
Recto ventral
Retractor ocular
Obliquo ventral
Elevador da pálpebra superior

 Base dos músculos esta na esclerotica onde tem as inserções

Importância do sistema visual:
Tem uma função essencial
Papel comportamental
Adaptação evolutiva
Impacto no desempenho
Vias nervosas visuais 
Anatomia e fototransdução
Correlação estrutura-função 
Particularidades veterinárias 

Estrutura refletora que amplifica a visão noturna- tapetum lucidum

Fotorecetores:
Cones (visão fotopica, diurna)
Bastonetes (visão escotópica, noturna)'
);

insert into public.sessions (student_id, unit_id, topic_id, session_type, session_date, session_time, title, notes)
values (
  (select id from public.students where full_name = 'Rita Bettencourt Afonso'),
  (select u.id from public.curriculum_units u join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Fisiologia II') limit 1),
  (select t.id from public.curriculum_topics t join public.curriculum_units u on u.id = t.unit_id join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Fisiologia II') and lower(t.title) like lower('%ruminantes%') limit 1),
  'aula',
  '2026-03-10',
  '11:00',
  'ruminantes',
  'Legado: aula-fisiologia-ii-ruminantes-2026-03-10.json

Rumen é estéril no nascimento.
Semana 1- colostro coloniza rúmen com flora materna, inicia se o processo de fermentação ruminal.
Semana 2 a 4- alimentos sólidos produzem AGV, butirato estimula o crescimento papilar ruminal progressivo. 
Semana 4 a 8- desenvolvimento progressivo papilar, aumentando volume ruminal, capacidade fermentativa aumenta. 
Mais de 8 semanas- rumen totalmente funcional, animal totalmente ruminante, goteira esofágica degenera com o tempo.

Acidose ruminal 
Causa desencadeadora- ingestão excessiva de concentrados com carboidratos de rápida fermentação ou mudança dietética abrupta desencadeia desequilíbrio ruminal.
Desregulação do pH- produção excessiva de AGV especialmente lactato, reduz pH ruminal abruptamente para valores inferiores a 5,5.
Morte microbiana- bactérias gram negativas morrem por acidificação, libertando endotoxinas (LPS) e lipoproteínas que danificam epitélio ruminal.
Resposta inflamatória sistémica- endotoxinas atravessam epitélio ruminal danificado, desencadeando resposta inflamatória generalizada em todo organismo.
Complicações clinicas- desenvolvimento de laminite, abcesso hepático, septicemia e potencial morte do animal se não tratado.

Acidose subclínica
Acidose aguda

Excesso de corpos cetónicos causam intoxicação no sistema nervoso central.

Deslocamento de abomaso:
- Definição e localização normal
- Deslocamento abomaso esquerdo
- Deslocamento abomaso direito
- Abordagem terapêutica
- Impacto na fisiologia digestiva 
- Manifestações clínicas 
- Causas e fatores predisponentes'
);

insert into public.sessions (student_id, unit_id, topic_id, session_type, session_date, session_time, title, notes)
values (
  (select id from public.students where full_name = 'Rita Bettencourt Afonso'),
  (select u.id from public.curriculum_units u join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Fisiologia II') limit 1),
  (select t.id from public.curriculum_topics t join public.curriculum_units u on u.id = t.unit_id join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Fisiologia II') and lower(t.title) like lower('%sistema visual%') limit 1),
  'aula',
  '2026-03-10',
  '14:00',
  'sistema visual',
  'Legado: aula-fisiologia-ii-sistema-visual-2026-03-10.json

A imagem é processada no córtex e a luminosidade é captada pelo olho.
Os objetos são os mesmos mas a perceção é diferente de ser vivo para ser vivo e de espécie para espécie.

Olho:
Córnea
Iris
Cristalino
Retina
Esclera
Pálpebras 
Terceira pálpebra é uma membrana
Pestanas 
Pupila
Nervo ótico

Canal naso lacrimal (drenagem das lágrimas)

Telasia- conjuntivite parasitaria

Miose- pupila fechada
Midríase- pupila dilatada'
);

insert into public.sessions (student_id, unit_id, topic_id, session_type, session_date, session_time, title, notes)
values (
  (select id from public.students where full_name = 'Rita Bettencourt Afonso'),
  (select u.id from public.curriculum_units u join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Fisiologia II') limit 1),
  (select t.id from public.curriculum_topics t join public.curriculum_units u on u.id = t.unit_id join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Fisiologia II') and lower(t.title) like lower('%Termorregulação nos animais domésticos%') limit 1),
  'aula',
  '2026-03-31',
  '14:00',
  'Termorregulação nos animais domésticos',
  'Legado: aula-fisiologia-ii-termorregulação-nos-animais-domésticos-2026-03-31.json
Avaliacao: 27 abril

Importância da homeotermia- funções enzimáticas, atividade metabólica e integridade celular, a manutenção da temperatura corporal dentro de limites externos é fundamental para a sobrevivência, variações externas comprometem funções
Termorregulação- processo fisiológico que permite aos animais manter a temperatura corporal estável mesmo perante variações ambientais. É essencial para a homeostasia e funcionamento adequado de todos os processos biológicos.

Falha na termorregulação:
Hipertermia 
Hipotermia 
Golpe de calor

Sala de cirurgia deve estar fria para manter a assepsia dos moveis e materiais para que não haja proliferação de bactérias e microrganismos, mas o animal deve estar quente.
Hipotálamo- centro regulador da temperatura.
Vias eferentes- a hipotálamo ativa mecanismos para corrigir desvios da temperatura (periféricas, centrais).
Vias aferentes- levam informação ao hipotálamo sobre a temperatura externa e interna (fisiológicas comportamentais)

Mecanismo de perda de calor:
Condução- ex: deitar no chão 
Radiação- perda de calor para o ambiente através de ondas sem contacto com outros objetos
Evaporação- perda de calor quando um líquido passa a vapor 
Convecção- movimento de fluidos, seja água ou ar

Mecanismo de produção de calor:
Termogénese por tremor- criar calor através da atividade muscular
Termogénese química- criar calor gastando substâncias de reserva como a gordura castanha (tecido adiposo castanho, TAC)
Regulação hormonal- T3 e T4 ajudam no metabolismo (definem a atividade consoante os níveis de T3 e T4) aumentam a taxa metabólica. Adrenalina e noradrenalina.

Perda de calor (por sudação):
Equino- muita
Bovino- limitada
Cão- apenas nas patas

Comportamentos:
Procurar sombras
Alterações corporais
Lamber o corpo

Cão- ofegação, para perder calor
Pelo- isolamento térmico para o calor e para o frio'
);

insert into public.sessions (student_id, unit_id, topic_id, session_type, session_date, session_time, title, notes)
values (
  (select id from public.students where full_name = 'Rita Bettencourt Afonso'),
  (select u.id from public.curriculum_units u join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Fisiologia II') limit 1),
  (select t.id from public.curriculum_topics t join public.curriculum_units u on u.id = t.unit_id join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Fisiologia II') and lower(t.title) like lower('%visão%') limit 1),
  'aula',
  '2026-03-17',
  '14:00',
  'visão',
  'Legado: aula-fisiologia-ii-visão-2026-03-17.json

Ciclo molecular da rodopsina:
Estrutura do pigmento visual
Absorção da luz
Recuperação
Cascata de sinalização (importante)
Sinalização neural
Hiperpolarização

Processamento retiniano e vias oticas:
Fotorecetores
Células bipolares e horizontais
Córtex visual primário
Corpo geniculado lateral e coliculo superior
Quiasma ótico
Células ganglionares

Diferenças enter-especies no quiasma ótico:
Carnívoros
Primatas (humanos)
Equinos
Ver quais as vantagens de cada um!!!!!! Importante

Reflexos visuais e acomodação:
Reflexo pupilar
Acomodação visual
Feedback visual motor
Proteção ocular

Particularidades do sistema visual canino:
Visão dicromática
Sensibilidade ao movimento
Visão noturna superior (tapetum lucidum)
Campo visual expandido

Felinos:
Pupila vertical
Foco próximo otimizado
Acuidade visual moderna
Visão em baixa luminosidade

Equino:
Anatomia ocular equina
Adaptação refletoriais
 Implicações comportamentais

Ruminantes:
Adaptações visuais
Visão noturna

Aves:
Capacidades sensoriais
Configuração ocular
Acomodação visual'
);

insert into public.sessions (student_id, unit_id, topic_id, session_type, session_date, session_time, title, notes)
values (
  (select id from public.students where full_name = 'Rita Bettencourt Afonso'),
  (select u.id from public.curriculum_units u join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Histologia e Embriologia') limit 1),
  (select t.id from public.curriculum_topics t join public.curriculum_units u on u.id = t.unit_id join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Histologia e Embriologia') and lower(t.title) like lower('%anexos embrionarios%') limit 1),
  'aula',
  '2026-03-04',
  '09:00',
  'anexos embrionarios',
  'Legado: aula-histologia-e-embriologia-anexos-embrionarios-2026-03-04.json
Avaliacao: 22 abril
Ficheiros anexos: Aula T3 - Formação dos anexos embrionários (1).pdf

Anexos embrionários (são eliminados após o nascimento):
Saco vitelino (armazenamento do vitelo)
Âmnio (mantem o embrião num meio aquoso)
Córion (mais externo)
Alantoide (funciona como deposito de metabolitos)
Placenta (apenas em mamíferos)

Saco vitelino- é o primeiro a ser formado, é formado pela esplancnopleura e faz trocas gasosas.
Placenta- é formada por córion e a alantoide mais endométrio.
Âmnio- tem origem na somatopleura pode se formar por pregueamento ou por cavitação.
Ver as diferenças entre repteis e aves
Córion- é formado pela somatopleura
Entre o córion e o amnio temos a alantoide
Albúmen- é a clara do ovo
Membrana coriovitelina é formada por córion e saco vitelino 
Alantoide funde-se com o córion formando a membrana alantocoriónica.
Córion viloso esta na placenta córion liso não esta na placenta esta fora.

Tipos de placenta:
Coriovitelina
Alantocoriónica 

Placentação:
Difusa (suínos)
Cotiledonar (ruminantes)
Zonária (cães e gatos)
Discoidal (humanos, macacos e roedores)

Placentação á ligação histoligica:
Epiteliocorial (placentas adecíduas)
Sinepiteliocorial (placentas adecíduas)
Endoteliocorial (placentas decíduas)
Hemocorial (placentas decíduas)

Cordão umbilical
Origem no córion e na alantoide, tem no seu interior duas artérias e uma veia.

Organogénese:
Células somáticas- formam todas as células menos as sexuais
Células germinativas- formam as gametas como os espermatozoides

Atividades celulares:
Divisões
Migração
Diferenciação
Alteração morfológica
Apoptose

Apoptose é a morte celular programada.'
);

insert into public.sessions (student_id, unit_id, topic_id, session_type, session_date, session_time, title, notes)
values (
  (select id from public.students where full_name = 'Rita Bettencourt Afonso'),
  (select u.id from public.curriculum_units u join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Histologia e Embriologia') limit 1),
  (select t.id from public.curriculum_topics t join public.curriculum_units u on u.id = t.unit_id join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Histologia e Embriologia') and lower(t.title) like lower('%Embriologia, mórula e blástula%') limit 1),
  'aula',
  '2026-02-18',
  '09:00',
  'Embriologia, mórula e blástula',
  'Legado: aula-histologia-e-embriologia-embriologia-mórula-e-blástula-2026-02-18.json
Avaliacao: 22 abril
Ficheiros anexos: Aula T1 - Mórula e Blástula (4).pdf

Clivagem – Divisões mitóticas, desdo zigoto a morula, os tamanhos são mais ou menos iguais apesar  do maior numero de divisões
Blastomeros maiores e menores (micrómeros e macrómeros)
O processo de passar de morula a blástula é o processo de blastulação
Vitelo- Reserva de nutrientes do zigoto, reserva proteica, o vitelo pode ser reduzido ou elevado
Classificação de zigoto consuante a quantidade de vitelo:
Isolecítico- pouco vitelo, distribuído uniformemente
Heterolecítico- pouco vitelo, distribuído de forma desigual
Telolecítico- muito vitelo
Centrolecítico- muito vitelo, concentrado no meio em volta do núcleo

Isolecítico- mamíferos e equinodermes (estrelas do mar)
Heterolecítico- peixes
Telolecítico- aves e repteis
Centrolecítico- insetos 

Compactação
Acontece após o estádio de 8 células, os blastómeros estão em comunicação, não estão sozinhos.
Embrioblastos
O processo é o mesmo em todos os mamíferos mas ocorre em tempo diferente.
Celoblástula- regular e irregular
Esteroblastula
Discoblastula

Pelúcida, serve para evitar uma gravidez ectópica, uma gravidez “fora do sitio”.

Blastocistole sai da zona pelúcida para se fixar no útero.'
);

insert into public.sessions (student_id, unit_id, topic_id, session_type, session_date, session_time, title, notes)
values (
  (select id from public.students where full_name = 'Rita Bettencourt Afonso'),
  (select u.id from public.curriculum_units u join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Histologia e Embriologia') limit 1),
  (select t.id from public.curriculum_topics t join public.curriculum_units u on u.id = t.unit_id join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Histologia e Embriologia') and lower(t.title) like lower('%Embriologia pratica%') limit 1),
  'aula',
  '2026-02-16',
  '16:00',
  'Embriologia pratica',
  'Legado: aula-histologia-e-embriologia-embriologia-pratica-2026-02-16.json
Avaliacao: 22 abril
Ficheiros anexos: Aula P1 e 2_Técnica Histológica (2).pdf

Tecnica Histologica
Maior parte dos tecidos não pode ser observada in vivo 
Obtenção da amostra:
Necropsia 
Biopsia 
Cirurgia

Planos:
Obliquo
Longitudinal
Transversal

Fixação:
Conservar as estruturas 
Evitar decomposição
Impedir atividade microbiana
Conferir maior rigidez ao tecido
Permitir cortes regulares
Fixadores podem ser naturais ou quimicos
Formol é o fixador mais importante (conserva)

Fatores que afetam a fixação:
pH
Osmoraliridade
Temperatura ambiente
Volume do fixador
Intervalo entre a colheita e por no fixador, quanto menor o intervalo melhor
Espessura da peça, quanto mais fina melhor

Processamento dos tecidos:
Corte da peça
Desidratação - Faz se com alcool em graduação crescente, serve para tirar a água para não haver bacterias (importante, vai sair no teste de certeza, este processo é importante)
Clarificação ou Diafanização - Faz se com Xilol para clarificar a peça
Impregnação - Faz se com Parafina, ponto de fusão 56-58 graus
O xilol substitui a água, a parafina substitui o xilol.

Corte - Utiliza-se o microtomo, nos usamos o rotativo.
Pos-corte - Colocamos a amostra em água fria e depois passa para um banho maria a 37 graus, depois seca na estufa.'
);

insert into public.sessions (student_id, unit_id, topic_id, session_type, session_date, session_time, title, notes)
values (
  (select id from public.students where full_name = 'Rita Bettencourt Afonso'),
  (select u.id from public.curriculum_units u join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Histologia e Embriologia') limit 1),
  (select t.id from public.curriculum_topics t join public.curriculum_units u on u.id = t.unit_id join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Histologia e Embriologia') and lower(t.title) like lower('%embriologia pratica%') limit 1),
  'aula',
  '2026-02-23',
  '16:00',
  'embriologia pratica',
  'Legado: aula-histologia-e-embriologia-embriologia-pratica-2026-02-23.json
Avaliacao: 22 abril
Ficheiros anexos: Aula P1 e 2_Técnica Histológica (2).pdf

Para fazer a coloração temos de hidratar a peça, é o processo contrário da desidratação.
Os núcleos das células são corados de azul e o resto de vermelho
Mordente--- muito importante vai sair no teste
Corante difusa- cora tudo
Seletiva- cora seletivamente as estruturas
Corantes artificiais ou sintéticos, ácidos e básicos--- importante sai no teste
Vamos trabalhar com a eosina se o corante é acido vai corar uma estrutura básica, estrutura acidófila, atrai o que é acido, ou seja “os opostos atraem se” ( e vice-versa).
Corantes básicos (hematoxilina) coram estruturas acidas, basófilas, atraem coisas básicas.
Hematoxilina- cora de azul ou violeta estruturas basófilas como os núcleos das células.
Eosina- cora de vermelho ou rosa estruturas acidófilas como o citoplasma das células.
Tendo as laminas hidratadas e coradas voltamos a desidratar com o processo do álcool em graduação crescente, com o xilol e depois com entellan.

Obtenção da amostra:
Fixação
Lavagem
Desidratação
Clarificação
Impregnação 
Desparafinar
Hidratar com álcool decrescente 
Coloração
Desidratar
Diafanizar'
);

insert into public.sessions (student_id, unit_id, topic_id, session_type, session_date, session_time, title, notes)
values (
  (select id from public.students where full_name = 'Rita Bettencourt Afonso'),
  (select u.id from public.curriculum_units u join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Histologia e Embriologia') limit 1),
  (select t.id from public.curriculum_topics t join public.curriculum_units u on u.id = t.unit_id join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Histologia e Embriologia') and lower(t.title) like lower('%Estômago%') limit 1),
  'aula',
  '2026-03-16',
  '16:00',
  'Estômago',
  'Legado: aula-histologia-e-embriologia-estômago-2026-03-16.json
Avaliacao: 22 abril
Ficheiros anexos: Aula P5 - Histologia Estômago e Gl. Submandibular.pdf

Estomago:
Túnica muscosa: pregas gástricas, epitélio colunar simples com invaginações.
Lâmina própria, é a parte mais clara em cima da mucosa.
Células parietais em células principais.
Estomago tem Ph ácido para formar o quimo.

No piloro só há células mucosas duodeno é Ph alcalino (básico)

Células da muscosa do estomago:
-Principais - pepsinogénio (inativa) – pepsina (ativa)
-parietais- (acido clorídrico)
-mucosas- (mucossecretoras)
-celulas do tronco- (vão se diferenciar)
-enteroendocrinas 

Importante- imagem da mucosa do estomago, ir a procura das células para identificar o local do estomago

Região pilórica 
Fúndica
Pilórica- pálidas e enoveladas 

Muscular:
Obliqua (mais interna)
Circular (intermedia)
Longitudinal (mais externa)
Estas camadas não contraem ao mesmo tempo. 


Glândulas salivares 
Sistema de ductos
Glândulas maiores (glândulas parótida, submandibular, sublingual)
Submandibular e sublingual são mistas 
Glândulas menores (linguais, bucais, labiais, palatinas)
(perceber bem as glândulas)

Primeiro ducto- ducto intrercalar, tem epitélio simples
Segundo ducto- ducto intralobular (dentro do lóbulo), epitélio lobular simples
Terceiro ducto- ducto interlobular (entre lóbulos), pseudoestratificado'
);

insert into public.sessions (student_id, unit_id, topic_id, session_type, session_date, session_time, title, notes)
values (
  (select id from public.students where full_name = 'Rita Bettencourt Afonso'),
  (select u.id from public.curriculum_units u join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Histologia e Embriologia') limit 1),
  (select t.id from public.curriculum_topics t join public.curriculum_units u on u.id = t.unit_id join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Histologia e Embriologia') and lower(t.title) like lower('%gastula%') limit 1),
  'aula',
  '2026-02-25',
  '09:00',
  'gastula',
  'Legado: aula-histologia-e-embriologia-gastula-2026-02-25.json
Avaliacao: 22 abril
Ficheiros anexos: Aula T2 - Gastrulação e Neurulação.pdf

Gatrulação- fase inicial 3 camadas

Involução
Epibolia 
Delaminação- formação do hipoblasto
Ingressão

Folhetos germinativos (animais triblásticos):
Ectoderme
Mesoderme
Endoderme

Diplasticos- so forfamam 2 folhetos germinativos não têm Mesoderme, ex: medusa e hidra.

Foice de Keller- onde se vai formar a linha primitiva.
A migração de células vai formar a Mesoderme.
A Mesoderme parte da linha primitiva. 

Tecidos embrionários 
Tecidos extraembrionarios- tecidos necessários apenas durante a gestação depois são descartados.

Trofoblasto:
Citotrofoblasto
Sinciciotroblasto

Lacunos- tem sangue materno

Não há junção com o sangue materno e o sangue embrionário, há sim passagem de nutrientes.

Disco embrionário (muito importante sai no teste)-epiblasto forma a ectoderme (camada superior), hipoblasto forma a endoderme e forma o saco vitelino (camada inferior).
Liquido amniótico- amortiza o impacto

Celona 
Acelomados- sem celoma, não têm cavidade.
Pseudocelomados- com cavidade, derivada de blastocélio, com mesoderme só no exterior.
Celomados- cavidade cheia de fluido delimitada pela mesoderme.

Linha primitiva
Gastrulação
Condensação de células do epiblasto
Sulco a volta
Fosseta (é um sulco)
Endoderme definitiva 
As células derivam de epiblasto e da origem os outras camadas. 

Diferenciação da mesoderme intraembrionaria:
Mesoderme paraxial
Mesoderme intermediaria
Mesoderme lateral

Somitos, divididos em 2 partes, esclerótomo (vai formar as vertebras e as costelas)  e dermomiotomo.

Fermatomo- pele- fibroblastos
Miótomo- musculo- mioblastolos
Neutocordomo-placa neural
Mesoderme-dos lados e em baixo da placa neural

Esplancnopleura
Membrana torácica 
Membrana abdominal'
);

insert into public.sessions (student_id, unit_id, topic_id, session_type, session_date, session_time, title, notes)
values (
  (select id from public.students where full_name = 'Rita Bettencourt Afonso'),
  (select u.id from public.curriculum_units u join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Histologia e Embriologia') limit 1),
  (select t.id from public.curriculum_topics t join public.curriculum_units u on u.id = t.unit_id join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Histologia e Embriologia') and lower(t.title) like lower('%Jejuno e pâncreas%') limit 1),
  'aula',
  '2026-03-23',
  '16:00',
  'Jejuno e pâncreas',
  'Legado: aula-histologia-e-embriologia-jejuno-e-pâncreas-2026-03-23.json
Avaliacao: 22 abril
Ficheiros anexos: Aula P6- Histologia Jejuno e Pâncreas.pdf

Jejuno:
Maior nº de células caliciformes
Sem glândulas de brunner nem placas de peyer
Núcleos basais
Células de paneth
Vilosidades 
Criptas 
Renovação celular de 3 dias
Epitélio colunar simples com microvilosidades
Submucosa- vasos linfático, vénulos
3 camadas de musculo
Plexo 
Serosa, peritoneu

Pâncreas: (anexo)
Glândula mista (comporta-se como glândula exócrina e como glândula endócrina) produz hormonas e suco pancreático
Secretina, estimula células a libertarem o bicarbonato
Acinos, formados por celulas acinosas com formação piramidal (produção de suco pâncreatica) 
Ilheus pancreáticos, onde são produzidas as hormonas (é pálido)
Alfa (glucagon)
Beta (insulina)
Delta (somatostanina, parácrino)
Celulas centoacinais
Glândula merócrina (halócrina, merócrina,aócrina)
Glândula cordonal 
Glândulas desimogenio'
);

insert into public.sessions (student_id, unit_id, topic_id, session_type, session_date, session_time, title, notes)
values (
  (select id from public.students where full_name = 'Rita Bettencourt Afonso'),
  (select u.id from public.curriculum_units u join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Histologia e Embriologia') limit 1),
  (select t.id from public.curriculum_topics t join public.curriculum_units u on u.id = t.unit_id join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Histologia e Embriologia') and lower(t.title) like lower('%língua e ílio%') limit 1),
  'aula',
  '2026-03-30',
  '16:00',
  'língua e ílio',
  'Legado: aula-histologia-e-embriologia-língua-e-ílio-2026-03-30.json
Ficheiros anexos: Aula P7 - Histologia Língua e Íleo.pdf

Língua 
Formada por:
Mucosa
Submucosa
Tecido muscular estriado esquelético  (feixes de fibras em todas as direções, as primeiras camadas são mais basófilas ou seja, mais roxas, as outras camadas tornam-se mais acidófilas, células mais planas em cima, epitélio de revestimento pavimentoso.

Submucosa- tecido linfático, vasos sanguíneos, infiltração de substancias na muscosa, epitélio estratificado pavimentoso.

Ventral não tem papilas e a dorsal tem e também tem queratina
Dorsal é mais larga que a ventral
Há mais papilas que não são recobertas por queratina e há 4 papilas diferentes: filiformes (não tem as gostativas), fungiformes, caliciformes e foliadas. (saber bem as diferenças entre as papilas e saber o epitélio do musculo)

Ilio 
Muitas células caliciformes  
Células M 
Placas de peyer (aglomerado de células linfoides)

Vilosidades mais pequenas
Não há glândulas de brunner'
);

insert into public.sessions (student_id, unit_id, topic_id, session_type, session_date, session_time, title, notes)
values (
  (select id from public.students where full_name = 'Rita Bettencourt Afonso'),
  (select u.id from public.curriculum_units u join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Histologia e Embriologia') limit 1),
  (select t.id from public.curriculum_topics t join public.curriculum_units u on u.id = t.unit_id join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Histologia e Embriologia') and lower(t.title) like lower('%Pancreas e sistema respiratório%') limit 1),
  'aula',
  '2026-03-18',
  '09:00',
  'Pancreas e sistema respiratório',
  'Legado: aula-histologia-e-embriologia-pancreas-e-sistema-respiratório-2026-03-18.json
Avaliacao: 22 abril
Ficheiros anexos: Aula T7 - Aparelho Urinário (1).pdf

Pâncreas tem origem na endoderme, formam-se 2 divertículos ao mesmo tempo.
É um anexo do trato digestivo.

Sistema respiratório:
Deriva de um divertículo respiratório / traquiobronquico, origem endodermica (o revestimento), orgem na mesoderme (cartilagem).

O divertículo vai se bifurcar formando os brônquios e vai se ramificando formando os pulmões.

Último ppt de embriologia, aparelho urinário

Sistema de filtração do sangue- glomérulos
Unidade funcional- nefrónio
Túbulos- onde vai ocorrendo a absorção
Ureter- tubo que liga os rins a bexiga

Nefrogénese- processo de formação dos rins

Prónefro- primeiro rim forma-se na região cefálica a partir da mesoderme intermedia

Canal prónefro passa a chamar-se canal mesonéfrico

Glomérulo externo- é responsável pela filtração do sangue, passando para o celoma, as células ciliadas vão conduzir o filtrado para o tubulo pronéfrico neste tubo há processo de reabsorção.

Anfíbios- canal mesonéfrico, calice mesonéfrico no cropusculo renal primitivo.

Metânefro- rim definitivo em amniotas
Cloaca- bexiga primitiva
Migração do metânefro (sai no teste)
Formação da bexiga
Úraco- porção da alantoide que não forma bexiga, forma a úraca

Tecidos fundamentais histologia 
Tecido epitelial

Histogénese

Características:
Morfologia celular
Membrana basal
Vascularização

Funções:
Proteção física 
Absorção
Secreção
Transporte de moléculas

Especialização da membrana:
Microvilosidades- absorção
Lamina basal- onde as células assentam
Hemidesmossomas- fixam as células na lamina
Gap juction- permite a comunicação entre células

Pseudo- estrtificados: núcleos mais acima e outras mais abaixo, todas as células assentam na membrana basal, mas nem todas alcançam a superfície apical.'
);

insert into public.sessions (student_id, unit_id, topic_id, session_type, session_date, session_time, title, notes)
values (
  (select id from public.students where full_name = 'Rita Bettencourt Afonso'),
  (select u.id from public.curriculum_units u join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Histologia e Embriologia') limit 1),
  (select t.id from public.curriculum_topics t join public.curriculum_units u on u.id = t.unit_id join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Histologia e Embriologia') and lower(t.title) like lower('%Sistema cardiovascular e aparelho digestivo e respiratorio%') limit 1),
  'aula',
  '2026-03-11',
  '09:00',
  'Sistema cardiovascular e aparelho digestivo e respiratorio',
  'Legado: aula-histologia-e-embriologia-sistema-cardiovascular-e-aparelho-digestivo-e-respiratorio-2026-03-11.json
Avaliacao: 22 abril
Ficheiros anexos: Aula T5 - Sistema Cardiovascular.pdf, Aula T6 - Aparelho Digestivo e Sistema Respiratório.pdf

Hematopoiese
Angiogenese

Hematopoiese:
Constituintes do sangue 
Linhagem linfoide
Linhagem eritro-mieloide
Mesoderme
O processo começa no saco vitelino

Locais de hematopoiese:
Linha primitiva
Saco vitelino
Região da aorta-gónada-mesonefros (AGM)
Placenta
Fígado
Medula óssea

Saco vitelino, fase mesoblástico:
- fase mesoblástica é uma fase extraembrionaria
- ilhéus sanguíneos de wolf e pander diferenciam-se em angioblastos (células mais externas) e hemancitoblastos (células mais internas) stas duas células são hemangioblastos.
AGM- intraembrionario

Angiogenese:
Placa cardiogénica (2 tubos)
Celoma origina a cavidade pericárdica
Placa cardigénica evolui para tubo endocárdico une-se as veias vitelinas formando o coração primitivo (tubular)

Origem de tecidos do coração:
- endocárdio
- miocárdio
- pericárdio visceral ou epitélio

Septação e formação de válvulas:
Septação separa circulação pulmonar da circulação após o nascimento
Septos intra-auriculares, intra ventriculares
Diferenciam-se as válvulas (aórtica, pulmonar, tricúspide e bicúspide)
Septos e válvulas permitem bombear sangue
Forâmen oval

Circulação fetal:
Ducto venoso
Forâmen oval a unir os átrios
Tronco pulmonar
Ducto arterioso

Quando nasce:
Encerramento do furamen oval
Encerramento do ducto arterioso
Encerramento das artérias umbilicais
Encerramento da veia umbilical
Encerramento do ducto venoso

Aparelho digestivo e respiratório
Animais triblasticos- tubo aberto nas extremidades
Animais biblasticos- tubo com uma abertura 
Formação de pregas- pregas subcefalicas e subcaudal 
Saco vitelino está inicialmente em continuidade com o instestino
Membrana oral- delimita o stomodeum
Membrana cloacal- delimita o proctodeum

Intestino primitivo:
Intestino anterior- origina a faringe, o esófago, fígado, o estomago, vesicula biliar e pâncreas
Intestino medio- duodeno, jejuno e ílio
Intestino posterior- colón'
);

insert into public.sessions (student_id, unit_id, topic_id, session_type, session_date, session_time, title, notes)
values (
  (select id from public.students where full_name = 'Rita Bettencourt Afonso'),
  (select u.id from public.curriculum_units u join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Histologia e Embriologia') limit 1),
  (select t.id from public.curriculum_topics t join public.curriculum_units u on u.id = t.unit_id join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Histologia e Embriologia') and lower(t.title) like lower('%tecido epitelial de revestimento%') limit 1),
  'aula',
  '2026-03-25',
  '09:00',
  'tecido epitelial de revestimento',
  'Legado: aula-histologia-e-embriologia-tecido-epitelial-de-revestimento-2026-03-25.json
Avaliacao: 22 abril
Ficheiros anexos: T1- Introdução à Histologia e Tecido Epitelial.pdf

Epitélio de revestimento simples colunar
Epitélio colunar simples ciliar

Epitélio simples pavimentoso- lamina basal ligada ao suporte da membrana. Este é o mais importante de todos: endotélio, mesotélio, alvéolos.


Epitélio simples cubóide- tem os núcleos bastante redondos.

Tiroide- secreção
Absorção- túbulos renais

Epitélio simples colunar:
No intestino tem sempre vilosidades
Produção de muco 
Muitas células colunares simples
Proteção e secreção

Epitélio colunar simples ciliado:
Proteção e secreção

Epitélio pseudoestratificado
Pseudoestratificado não ciliado (uretra prostática)
Pseudoestratificado ciliado (lumen e em órgão respiratórios, função é proteção através do dispositivo mucociliar
Pseudoestratificado com estereocilios (no epidídimo)

Epitélio estratificado: 
Estratificado pavimentoso (lamina basal, células poliédricas, tem 4 camadas, não queratinizado em superfícies húmidas. Queratinizado, tem 5 camadas (saber muito bem estas 5 camadas).
Estratificado cubico (em glândulas e ductos uretrais, 3 camadas)
Estratificado colunar (proteção e secreção, 3 camadas (ter em atenção pois estas 3 camadas são muito parecidas com as 3 camadas do estratificado cubico).
Estratificado de transição (reveste, 8 camadas quando relaxado, 2 camadas quando estirado (esticado). As células de superfície vão mudando de forma, na bexiga quando não há urina as células superficiais ficam concavas quando a bexiga esta cheia ficam planas. Há uma membrana por cima das células superficiais que protege estas células da urina)'
);

insert into public.sessions (student_id, unit_id, topic_id, session_type, session_date, session_time, title, notes)
values (
  (select id from public.students where full_name = 'Rita Bettencourt Afonso'),
  (select u.id from public.curriculum_units u join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Histologia e Embriologia') limit 1),
  (select t.id from public.curriculum_topics t join public.curriculum_units u on u.id = t.unit_id join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Histologia e Embriologia') and lower(t.title) like lower('%tecido epitelial glandular%') limit 1),
  'aula',
  '2026-04-01',
  '09:00',
  'tecido epitelial glandular',
  'Legado: aula-histologia-e-embriologia-tecido-epitelial-glandular-2026-04-01.json
Avaliacao: 22 abril
Ficheiros anexos: T2-Tecido Epitelial Glandular.pdf

Embriogénese 

Classificação:
Local onde é libertada a secreção (saber isto muito bem):
Endócrina
Exócrina
Mista (pâncreas)

Número de células que formam a glândula:
Unicelulares (caliciformes)
Pluricelulares (glândulas intraepiteliais podem ser homocrinas ou heterocrinas, o tubo excretor pode ser simples ou composto)

Forma dos adenómeros:
Acinar 
Alveolar
Tubular

Nº de camadas celulares das adenómeros:
Uniestratificados 
Pluriestratificados

Ramificação dos adenomeros:
Ramificados 
Não ramificados

Forma dos adenomeros:
Tubulares 
Tubuloacinosas
Tubuloalveolares

Natureza química da secreção: 
Mucosa
Serosa
Mista

Mecanismo de libertação da secreção:
Holócrinas (glândulas cebacias)
Merócrinas (pâncreas, parótida)
Apócrinas ( glândula mamaria)

Adenomero- parte secretora com celulças secretoras e mioepiteliais'
);

insert into public.sessions (student_id, unit_id, topic_id, session_type, session_date, session_time, title, notes)
values (
  (select id from public.students where full_name = 'Rita Bettencourt Afonso'),
  (select u.id from public.curriculum_units u join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Histologia e Embriologia') limit 1),
  (select t.id from public.curriculum_topics t join public.curriculum_units u on u.id = t.unit_id join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Histologia e Embriologia') and lower(t.title) like lower('%tubo digestivo%') limit 1),
  'aula',
  '2026-03-02',
  '16:00',
  'tubo digestivo',
  'Legado: aula-histologia-e-embriologia-tubo-digestivo-2026-03-02.json
Avaliacao: 22 Abril

Órgãos tubulares (todos têm 4 camadas):
Mucosas (epitélio, camada que reveste a muscosa)
Submucosa
Muscular
Serosa ou adventícia 

Esófago:
Epitélio – estratificado, simples ou pseudoestratificado
Epitélio- pavimentoso, cúbico ou colunar
Esófago- epitélio estratificado pavimentoso

Submucosa- muscular da mucosa (musculo liso)
Submucosa- constituída por epitélio tem tecido conjuntivo, produtora de muco.

Túnica muscular (2 ou 3 camadas):
Esófago tem camadas:
Camada interna (circular)
Camada externa (longitudinal)

Ruminantes só têm musculo estriado esquelético para conseguirem regurgitar o alimento.

Serosas- mesotélio mais tecido conjuntivo laxo
Serosas- no interior de cavidades
Mesotélio- epitélio pavimentoso simples

Adventícia- tecido conjuntivo laxo

Morfologia das células da ultima camada dão o nome ao epitélio.

Fígado:
Função: 
Secreção de bílis (hepatócitos, células principais do fígado)
Armazenamento de glucose sanguínea
Neutraliza e elimina substâncias toxicas

Circulação hepática:
Vascularização aferente – veia porta e artéria hepática
Vascularização eferente- veias hepáticas

Ramo da veia porta
Ramo da artéria hepática

Fígado é dividido em lóbulos 

Tríade portal:
Ramo da veia porta
Ramo da artéria hepática
Ducto biliar

O sangue entra no fígado pela veia porta e artéria hepática, estes vão se ramificar.
O sangue e a bílis andam em sentidos opostos.

Endotélio-revestimento dos vasos sanguíneos.
Endotélio- células que formam o endotélio são as células endoteliais.
Mesotélio- células mesoteliais.
Ducto biliar- constituído por epitélio cubico simples.

Ultraestrutura
Sinusoide- revestido com epitélio simples, células endoteliais, células de kupffer especificas do fígado, tem um espaço de Disse onde tem células de Ito.
Hepatositos- polo vascular (em cima) e polo basal (em baixo)'
);

insert into public.sessions (student_id, unit_id, topic_id, session_type, session_date, session_time, title, notes)
values (
  (select id from public.students where full_name = 'Rita Bettencourt Afonso'),
  (select u.id from public.curriculum_units u join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Histologia e Embriologia') limit 1),
  (select t.id from public.curriculum_topics t join public.curriculum_units u on u.id = t.unit_id join public.curricula c on c.id = u.curriculum_id where c.slug = 'esa-enfermagem-veterinaria-2025' and lower(u.title) = lower('Histologia e Embriologia') and lower(t.title) like lower('%tubo digestivo duodeno e timo%') limit 1),
  'aula',
  '2026-03-09',
  '16:00',
  'tubo digestivo duodeno e timo',
  'Legado: aula-histologia-e-embriologia-tubo-digestivo-duodeno-e-timo-2026-03-09.json
Avaliacao: 22 abril
Ficheiros anexos: Aula P4 - Histologia Duodeno e Timo.pdf

Duodeno:
1 camada de células
Mucosa (lâmina própria, epitélio simples colunar) túnicas.
Submucosa (glândulas: serosa, mista ou musoca)
Vilosidades para absorver os nutrientes dos alimentos
A lâmina própria dá preenchimento às vilosidades 
Criptas é a parte mais baixa logo a seguir as vilosidades
Enterocitos é uma célula intestina.
Secretina é uma hormona que liberta bicarbonato
Células regeneradoras vão se diferenciar num tipo específico de célula
Muscular- camada circular, cmada longitudinal externa e interna

Timo:
Maturação de linfócitos T (há muitos no córtex e menos na medula)
Células epiteliais reticulares, migram e formam camadas, formando o corpúsculo de Hassal.
Estroma, cápsula de tecido conjuntivo denso.
Barreira hemato- tímica- so existe no córtex (saber as estruturas que a constituem e para que serve).'
);

commit;

-- Total de aulas legadas importadas: 33
-- FIM DO SEED
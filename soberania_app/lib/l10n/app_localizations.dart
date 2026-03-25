import 'package:flutter/material.dart';

import 'locale_scope.dart';

/// Traduções PT, EN, ES. Use [AppLocalizations.t(context, key)].
class AppLocalizations {
  AppLocalizations._(this._locale);

  final Locale _locale;
  static const _fallback = 'pt';

  String get _lang => _locale.languageCode;

  static const Map<String, Map<String, String>> _data = {
    'pt': {
      'app_title': 'Soberania Digital',
      'welcome_title': 'Descubra o nível de maturidade digital da sua empresa.',
      'welcome_line1': 'Descubra o nível de maturidade digital da sua empresa.',
      'welcome_line2': 'Faça um diagnóstico e descubra em que estágio sua operação se encontra',
      'welcome_line3': 'com o assessment exclusivo da SoftwareOne e AWS.',
      'btn_login': 'Entrar',
      'btn_signup': 'Cadastre-se',
      'btn_logout': 'Sair',
      'intro_title': 'Entenda o Assessment',
      'intro_subtitle': 'Assessment de Maturidade',
      'intro_before_start': 'Antes de começar',
      'intro_desc': 'Entenda mais sobre a SoftwareOne e o Assessment de Maturidade em Soberania Digital.',
      'intro_time': 'Tempo estimado: 5–10 min',
      'intro_page_title': 'Introdução',
      'intro_page_subtitle':
          'Controle, segurança e autonomia para a operação digital.',
      'intro_chat_welcome':
          'Ficou com alguma dúvida em relação ao assessment ou sobre soberania digital? Fique à vontade para me perguntar!',
      'intro_framework_title':
          'Framework dos 3 Cs: Nossa Metodologia de Avaliação',
      'intro_framework_bullet_1':
          'A metodologia da SoftwareOne avalia a soberania digital a partir de três pilares: Compliance, Control e Continuity.',
      'intro_framework_bullet_2':
          'O framework oferece uma visão prática da maturidade da organização.',
      'intro_framework_bullet_3':
          'Ajuda a identificar prioridades de evolução e construção de um roadmap.',
      'intro_compliance_title': 'Compliance',
      'intro_compliance_bullet_1':
          'Conformidade com leis, normas e padrões de segurança.',
      'intro_compliance_bullet_2':
          'Transforma exigências regulatórias em critérios claros de avaliação e decisão.',
      'intro_control_title': 'Control',
      'intro_control_bullet_1':
          'Controle sobre infraestrutura, acessos, dados e chaves.',
      'intro_control_bullet_2':
          'Reforça autoridade operacional, proteção de ativos críticos e autonomia tecnológica.',
      'intro_continuity_title': 'Continuity',
      'intro_continuity_bullet_1':
          'Capacidade de resistir, responder e se recuperar.',
      'intro_continuity_bullet_2':
          'Fortalece a continuidade do negócio diante de falhas, crises e eventos externos.',
      'intro_about_card_title': 'Sobre a SoftwareOne',
      'intro_about_card_body':
          'A SoftwareOne é uma empresa global de soluções em tecnologia, com atuação em modernização digital, nuvem, dados, segurança e governança. Com profundo conhecimento técnico, experiência prática em ambientes regulados e reconhecimento como AWS Premier Partner, a empresa entrega projetos com alto padrão de qualidade, segurança e consistência operacional.',
      'intro_assessment_card_title':
          'Assessment de Maturidade em Soberania Digital',
      'intro_assessment_card_body':
          'O Assessment de Maturidade em Soberania Digital avalia, de forma estruturada, o nível de controle, conformidade, resiliência e independência digital da organização. Com critérios objetivos, mensuráveis e auditáveis, a avaliação mostra o cenário atual, identifica lacunas e apoia a definição de um roadmap pragmático e alinhado às exigências do negócio e da regulação.',
      'intro_what_title': '📋 O que é',
      'intro_what_body':
          'O Assessment de Maturidade em Soberania Digital da SoftwareOne avalia de forma estruturada o nível de controle, conformidade, resiliência e independência digital da organização. A avaliação considera aspectos técnicos, operacionais, organizacionais e regulatórios, fornecendo uma visão clara do estado atual, das lacunas existentes e das prioridades de evolução. O assessment é baseado em critérios objetivos, mensuráveis e auditáveis, permitindo classificar a maturidade e apoiar a definição de um roadmap pragmático e alinhado às exigências do negócio e da regulação.',
      'intro_about_title': '🏢 Sobre a SoftwareOne',
      'intro_about_body':
          'A SoftwareOne é uma empresa global de soluções em tecnologia, com sede na Suíça e operação no Brasil, apoiando organizações em sua jornada de modernização e transformação digital. Atuamos como parceiros estratégicos de nossos clientes, combinando profundo conhecimento técnico, experiência em ambientes de nuvem, dados e segurança, e entendimento prático das exigências regulatórias locais e globais. Como AWS Premier Partner, a SoftwareOne integra o mais alto nível de parceria da AWS, reconhecido por excelência técnica comprovada, histórico consistente de entregas bem-sucedidas e equipes altamente certificadas, o que atesta nossa capacidade de projetar, implementar e operar ambientes complexos e críticos na nuvem com padrões rigorosos de qualidade, segurança e governança.',
      'intro_partnership_title':
          'Parceria SoftwareOne e AWS em Soberania Digital',
      'intro_partnership_body':
          'A SoftwareOne é parceira estratégica da AWS para o tema de Soberania Digital, sendo a única empresa no Brasil e uma das poucas no mundo com essa competência reconhecida. Essa parceria une profundo conhecimento técnico em ambientes de nuvem com expertise nas exigências regulatórias locais e globais, permitindo apoiar organizações na construção de estratégias de soberania digital alinhadas às demandas de negócio, aos requisitos legais e aos desafios operacionais de ambientes digitais modernos e distribuídos.',
      'intro_sov_title': 'Soberania Digital',
      'intro_sov_body':
          'Soberania Digital é a capacidade de uma organização manter controle, autoridade e visibilidade sobre seus dados, infraestrutura e operações digitais, assegurando conformidade regulatória, segurança, resiliência operacional, transparência e independência tecnológica. Em ambientes de nuvem, a soberania digital possibilita atender a requisitos regulatórios e geopolíticos crescentes sem comprometer agilidade, inovação ou escala, criando uma base sustentável para inovação segura e crescimento contínuo.',
      'intro_challenges_title': '⚠️ Principais desafios enfrentados',
      'intro_challenge_1':
          'Conformidade simultânea com múltiplas legislações e regulações nacionais e internacionais.',
      'intro_challenge_2':
          'Garantia de residência, movimentação e controle de dados em ambientes distribuídos.',
      'intro_challenge_3':
          'Restrição e governança de acessos operacionais, incluindo operadores internos e terceiros.',
      'intro_challenge_4':
          'Falta de visibilidade contínua e evidências auditáveis de conformidade.',
      'intro_challenge_5':
          'Necessidade de resiliência e continuidade operacional frente a incidentes, falhas sistêmicas ou eventos geopolíticos.',
      'intro_challenge_6':
          'Escassez de competências especializadas para projetar, operar e evoluir ambientes soberanos.',
      'intro_benefits_title': '✅ Principais benefícios',
      'intro_benefit_1':
          'Redução de riscos regulatórios, operacionais e reputacionais.',
      'intro_benefit_2':
          'Maior transparência e auditabilidade dos ambientes digitais.',
      'intro_benefit_3':
          'Controle efetivo sobre dados, infraestrutura e operações críticas.',
      'intro_benefit_4':
          'Continuidade e resiliência dos negócios, mesmo em cenários extremos.',
      'intro_benefit_5':
          'Aumento da confiança de clientes, parceiros e órgãos reguladores.',
      'intro_benefit_6':
          'Base sólida para inovação segura, incluindo dados sensíveis e cargas de trabalho críticas.',
      'btn_start_assessment': 'Iniciar Assessment',
      'phases_title': 'Pilares da Soberania Digital',
      'phases_choose': 'Escolha um pilar para responder',
      'phase_compliance_label': 'Compliance',
      'phase_compliance_subtitle': 'Conformidade e requisitos regulatórios',
      'phase_continuity_label': 'Continuity',
      'phase_continuity_subtitle': 'Continuidade de negócio e resiliência',
      'phase_control_label': 'Control',
      'phase_control_subtitle': 'Controles e governança',
      'results_title': 'Resultados',
      'results_score_by_pillar': 'Score por Pilar',
      'results_score_by_domain': 'Score por Domínio',
      'results_no_data': 'Nenhum dado disponível.',
      'results_overview_loading': 'O Bot está analisando os resultados...',
      'results_retry': 'Tentar novamente',
      'results_radar_empty': 'Sem dados para radar',
      'results_generated_at': 'Gerado em',
      'results_view_scores': 'Ver seus gráficos de pontuação',
      'results_available_hint':
          'Responda todas as questões de todas as fases para ver os resultados.',
      'results_new_generated': 'Novo resultado gerado!',
      'phases_obs':
          'Obs: os valores dos pilares (Compliance, Continuity, Control) devem corresponder ao campo "pilar" das questões no Xano.',
      'results_provided_by': 'Fornecidos por',
      'domain_continuity_portability': 'Continuidade e Portabilidade',
      'domain_governance_compliance': 'Governança e Conformidade',
      'domain_operational_sovereignty': 'Soberania Operacional',
      'domain_organizational_sovereignty': 'Soberania Organizacional',
      'domain_data_sovereignty': 'Soberania de Dados',
      'domain_infrastructure_sovereignty': 'Soberania de Infraestrutura',
      'back_to_pillars': 'Voltar para pilares',
      'go_to_intro': 'Ir para introdução',
      'lang_pt': 'Português',
      'lang_en': 'English',
      'lang_es': 'Español',
      'login_title': 'Acesso',
      'login_card_title': 'Acesse sua conta',
      'login_welcome_title': 'Seja bem-vindo',
      'login_subtitle': 'Insira seus dados para continuar.',
      'login_email_label': 'E-mail',
      'login_email_required': 'Informe seu e-mail',
      'login_email_invalid': 'E-mail inválido',
      'login_password_label': 'Senha',
      'login_password_required': 'Informe sua senha',
      'login_tip_config_xano': 'Dica: configure a URL do Xano em lib/config.dart',
      'login_forgot_password': 'Esqueci minha senha',
      'login_forgot_success':
          'Se este e-mail estiver cadastrado, você receberá instruções para redefinir sua senha.',
      'signup_title': 'Cadastre-se',
      'signup_heading': 'Criar conta',
      'signup_subtitle': 'Vamos começar! Crie sua conta em poucos passos.',
      'signup_name_label': 'Primeiro Nome',
      'signup_name_hint': 'Seu primeiro nome',
      'signup_name_required': 'Informe seu primeiro nome',
      'signup_lastname_label': 'Último Nome',
      'signup_lastname_hint': 'Seu último nome',
      'signup_lastname_required': 'Informe seu último nome',
      'signup_email_label': 'E-mail',
      'signup_email_hint': 'seu@email.com',
      'signup_email_required': 'Informe seu e-mail',
      'signup_email_invalid': 'E-mail inválido',
      'signup_phone_label': 'Telefone',
      'signup_phone_hint': '(11) 99999-9999',
      'signup_phone_required': 'Informe seu telefone',
      'signup_phone_invalid': 'Telefone deve ter 10 ou 11 dígitos (com DDD)',
      'signup_company_label': 'Empresa',
      'signup_company_hint': 'Nome da sua empresa',
      'signup_company_required': 'Informe a empresa',
      'signup_role_label': 'Cargo',
      'signup_role_hint': 'Ex: Gerente, Analista',
      'signup_password_label': 'Escolha uma senha',
      'signup_password_required': 'Informe uma senha',
      'signup_password_too_short': 'Senha deve ter no mínimo 6 caracteres',
      'btn_register': 'Criar minha conta',
      'signup_already_have': 'Já tem conta? ',
      'no_account': 'Não tem uma conta ainda? Cadastre-se',
      'right_panel_title': 'O que oferecemos',
      'right_panel_intro':
          'Na plataforma de Soberania Digital da SoftwareOne + AWS, você pode:',
      'right_panel_topics':
          'Avaliar a maturidade digital nos pilares Compliance, Control e Continuity.\n\n'
          'Responder a um assessment guiado por fases, com progresso salvo.\n\n'
          'Visualizar pontuações por pilar e por domínio com gráficos.\n\n'
          'Receber análise automatizada do bot com recomendações práticas.\n\n'
          'Identificar lacunas, riscos e prioridades para evolução.\n\n'
          'Apoiar a construção de um roadmap alinhado ao negócio e à regulação.',
    },
    'en': {
      'app_title': 'Digital Sovereignty',
      'welcome_title': "Discover your company's digital maturity level.",
      'welcome_line1': "Discover your company's digital maturity level.",
      'welcome_line2': "Run a diagnosis and find out what stage your operation is at",
      'welcome_line3': "with the exclusive SoftwareOne and AWS assessment.",
      'btn_login': 'Log in',
      'btn_signup': 'Sign up',
      'btn_logout': 'Log out',
      'intro_title': 'Understand the Assessment',
      'intro_subtitle': 'Maturity Assessment',
      'intro_before_start': 'Before you start',
      'intro_desc': 'Learn more about SoftwareOne and the Digital Sovereignty Maturity Assessment.',
      'intro_time': 'Estimated time: 5–10 min',
      'intro_page_title': 'Introduction',
      'intro_page_subtitle':
          'Control, security, and autonomy for digital operations.',
      'intro_chat_welcome':
          'Do you have any questions about the assessment or digital sovereignty? Feel free to ask me!',
      'intro_framework_title':
          'The 3Cs Framework: Our Assessment Methodology',
      'intro_framework_bullet_1':
          'SoftwareOne methodology evaluates digital sovereignty across three pillars: Compliance, Control, and Continuity.',
      'intro_framework_bullet_2':
          'The framework provides a practical view of the organization maturity level.',
      'intro_framework_bullet_3':
          'It helps identify evolution priorities and build a roadmap.',
      'intro_compliance_title': 'Compliance',
      'intro_compliance_bullet_1':
          'Compliance with laws, standards, and security requirements.',
      'intro_compliance_bullet_2':
          'Turns regulatory demands into clear evaluation and decision criteria.',
      'intro_control_title': 'Control',
      'intro_control_bullet_1':
          'Control over infrastructure, access, data, and keys.',
      'intro_control_bullet_2':
          'Reinforces operational authority, protection of critical assets, and technological autonomy.',
      'intro_continuity_title': 'Continuity',
      'intro_continuity_bullet_1':
          'Ability to resist, respond, and recover.',
      'intro_continuity_bullet_2':
          'Strengthens business continuity in the face of failures, crises, and external events.',
      'intro_about_card_title': 'About SoftwareOne',
      'intro_about_card_body':
          'SoftwareOne is a global technology solutions company focused on digital modernization, cloud, data, security, and governance. With deep technical expertise, practical experience in regulated environments, and recognition as an AWS Premier Partner, the company delivers projects with high standards of quality, security, and operational consistency.',
      'intro_assessment_card_title':
          'Digital Sovereignty Maturity Assessment',
      'intro_assessment_card_body':
          'The Digital Sovereignty Maturity Assessment evaluates, in a structured way, the organization level of control, compliance, resilience, and digital independence. Using objective, measurable, and auditable criteria, the assessment shows the current scenario, identifies gaps, and supports the definition of a pragmatic roadmap aligned with business and regulatory requirements.',
      'intro_what_title': '📋 What it is',
      'intro_what_body':
          'The Digital Sovereignty Maturity Assessment from SoftwareOne provides a structured view of your level of control, compliance, resilience, and digital independence. It considers technical, operational, organizational, and regulatory aspects to give a clear picture of the current state, existing gaps, and evolution priorities. The assessment is based on objective, measurable, and auditable criteria, helping classify maturity and define a pragmatic roadmap aligned with business and regulatory requirements.',
      'intro_about_title': '🏢 About SoftwareOne',
      'intro_about_body':
          'SoftwareOne is a global technology solutions company headquartered in Switzerland with operations in Brazil, supporting organizations in their journey of modernization and digital transformation. We act as a strategic partner to our customers by combining deep technical expertise, experience in cloud, data, and security, and practical understanding of local and global regulatory requirements. As an AWS Premier Partner, SoftwareOne is part of the highest partnership level with AWS, recognized for proven technical excellence, a consistent track record of successful deliveries, and highly certified teams, demonstrating our ability to design, implement, and operate complex and mission-critical cloud environments with strict quality, security, and governance standards.',
      'intro_partnership_title':
          'SoftwareOne and AWS partnership on Digital Sovereignty',
      'intro_partnership_body':
          'SoftwareOne is a strategic AWS partner for Digital Sovereignty and is the only company in Brazil, and one of the few worldwide, with this recognized competency. This partnership combines deep technical knowledge of cloud environments with expertise in local and global regulatory requirements, enabling organizations to build digital sovereignty strategies that are aligned with business demands, legal obligations, and the operational challenges of modern, distributed digital environments.',
      'intro_sov_title': 'Digital Sovereignty',
      'intro_sov_body':
          'Digital sovereignty is the ability of an organization to maintain control, authority, and visibility over its data, infrastructure, and digital operations, ensuring regulatory compliance, security, operational resilience, transparency, and technological independence. In cloud environments, digital sovereignty makes it possible to meet increasing regulatory and geopolitical requirements without compromising agility, innovation, or scale, creating a sustainable foundation for secure innovation and continuous growth.',
      'intro_challenges_title': '⚠️ Key challenges',
      'intro_challenge_1':
          'Achieving simultaneous compliance with multiple national and international laws and regulations.',
      'intro_challenge_2':
          'Ensuring data residency, movement, and control in distributed environments.',
      'intro_challenge_3':
          'Restricting and governing operational access, including internal operators and third parties.',
      'intro_challenge_4':
          'Lack of continuous visibility and auditable evidence of compliance.',
      'intro_challenge_5':
          'Need for resilience and business continuity in the face of incidents, systemic failures, or geopolitical events.',
      'intro_challenge_6':
          'Shortage of specialized skills to design, operate, and evolve sovereign environments.',
      'intro_benefits_title': '✅ Main benefits',
      'intro_benefit_1':
          'Reduction of regulatory, operational, and reputational risks.',
      'intro_benefit_2':
          'Greater transparency and auditability of digital environments.',
      'intro_benefit_3':
          'Effective control over data, infrastructure, and critical operations.',
      'intro_benefit_4':
          'Business continuity and resilience even in extreme scenarios.',
      'intro_benefit_5':
          'Increased trust from customers, partners, and regulators.',
      'intro_benefit_6':
          'A solid foundation for secure innovation, including sensitive data and mission-critical workloads.',
      'btn_start_assessment': 'Start Assessment',
      'phases_title': 'Digital Sovereignty Pillars',
      'phases_choose': 'Choose a pillar to answer',
      'phase_compliance_label': 'Compliance',
      'phase_compliance_subtitle': 'Compliance and regulatory requirements',
      'phase_continuity_label': 'Continuity',
      'phase_continuity_subtitle': 'Business continuity and resilience',
      'phase_control_label': 'Control',
      'phase_control_subtitle': 'Controls and governance',
      'results_title': 'Results',
      'results_score_by_pillar': 'Score by Pillar',
      'results_score_by_domain': 'Score by Domain',
      'results_no_data': 'No data available.',
      'results_overview_loading': 'The bot is analyzing the results...',
      'results_retry': 'Try again',
      'results_radar_empty': 'No data for radar',
      'results_generated_at': 'Generated at',
      'results_view_scores': 'View your score charts',
      'results_available_hint':
          'Answer all questions in every phase to see the results.',
      'results_new_generated': 'New result generated!',
      'phases_obs':
          'Note: the pillar values (Compliance, Continuity, Control) must match the "pilar" field of the questions in Xano.',
      'results_provided_by': 'Provided by',
      'domain_continuity_portability': 'Continuity and Portability',
      'domain_governance_compliance': 'Governance and Compliance',
      'domain_operational_sovereignty': 'Operational Sovereignty',
      'domain_organizational_sovereignty': 'Organizational Sovereignty',
      'domain_data_sovereignty': 'Data Sovereignty',
      'domain_infrastructure_sovereignty': 'Infrastructure Sovereignty',
      'back_to_pillars': 'Back to pillars',
      'go_to_intro': 'Go to introduction',
      'lang_pt': 'Português',
      'lang_en': 'English',
      'lang_es': 'Español',
      'login_title': 'Log in',
      'login_card_title': 'Access your account',
      'login_welcome_title': 'Welcome',
      'login_subtitle': 'Enter your details to continue.',
      'login_email_label': 'Email',
      'login_email_required': 'Enter your email',
      'login_email_invalid': 'Invalid email',
      'login_password_label': 'Password',
      'login_password_required': 'Enter your password',
      'login_tip_config_xano': 'Tip: configure the Xano URL in lib/config.dart',
      'login_forgot_password': 'Forgot your password?',
      'login_forgot_success':
          'If this email is registered, you will receive instructions to reset your password.',
      'signup_title': 'Sign up',
      'signup_heading': 'Create account',
      'signup_subtitle': "Let's get started! Create your account in a few steps.",
      'signup_name_label': 'First name',
      'signup_name_hint': 'Your first name',
      'signup_name_required': 'Enter your first name',
      'signup_lastname_label': 'Last name',
      'signup_lastname_hint': 'Your last name',
      'signup_lastname_required': 'Enter your last name',
      'signup_email_label': 'Email',
      'signup_email_hint': 'you@email.com',
      'signup_email_required': 'Enter your email',
      'signup_email_invalid': 'Invalid email',
      'signup_phone_label': 'Phone',
      'signup_phone_hint': '(11) 99999-9999',
      'signup_phone_required': 'Enter your phone number',
      'signup_phone_invalid': 'Phone must have 10 or 11 digits (with area code)',
      'signup_company_label': 'Company',
      'signup_company_hint': 'Your company name',
      'signup_company_required': 'Enter the company',
      'signup_role_label': 'Role',
      'signup_role_hint': 'e.g. Manager, Analyst',
      'signup_password_label': 'Choose a password',
      'signup_password_required': 'Enter a password',
      'signup_password_too_short': 'Password must be at least 6 characters',
      'btn_register': 'Create my account',
      'signup_already_have': 'Already have an account? ',
      'no_account': "Don't have an account yet? Sign up",
      'right_panel_title': 'What we offer',
      'right_panel_intro':
          'On the SoftwareOne + AWS Digital Sovereignty platform, you can:',
      'right_panel_topics':
          'Assess digital maturity across the Compliance, Control, and Continuity pillars.\n\n'
          'Complete a guided assessment by phases, with saved progress.\n\n'
          'View scores by pillar and by domain with charts.\n\n'
          'Receive automated bot analysis with practical recommendations.\n\n'
          'Identify gaps, risks, and priorities for evolution.\n\n'
          'Support the creation of a roadmap aligned with business and regulatory requirements.',
    },
    'es': {
      'app_title': 'Soberanía Digital',
      'welcome_title': 'Descubra el nivel de madurez digital de su empresa.',
      'welcome_line1': 'Descubra el nivel de madurez digital de su empresa.',
      'welcome_line2': 'Realice un diagnóstico y descubra en qué etapa se encuentra su operación',
      'welcome_line3': 'con el assessment exclusivo de SoftwareOne y AWS.',
      'btn_login': 'Entrar',
      'btn_signup': 'Registrarse',
      'btn_logout': 'Salir',
      'intro_title': 'Entienda el Assessment',
      'intro_subtitle': 'Assessment de Madurez',
      'intro_before_start': 'Antes de comenzar',
      'intro_desc': 'Conozca más sobre SoftwareOne y el Assessment de Madurez en Soberanía Digital.',
      'intro_time': 'Tiempo estimado: 5–10 min',
      'intro_page_title': 'Introducción',
      'intro_page_subtitle':
          'Control, seguridad y autonomía para la operación digital.',
      'intro_chat_welcome':
          '¿Tiene alguna duda sobre el assessment o sobre soberanía digital? ¡No dude en preguntarme!',
      'intro_framework_title':
          'Framework de las 3 C: Nuestra Metodología de Evaluación',
      'intro_framework_bullet_1':
          'La metodología de SoftwareOne evalúa la soberanía digital a partir de tres pilares: Compliance, Control y Continuity.',
      'intro_framework_bullet_2':
          'El framework ofrece una visión práctica de la madurez de la organización.',
      'intro_framework_bullet_3':
          'Ayuda a identificar prioridades de evolución y construcción de una hoja de ruta.',
      'intro_compliance_title': 'Compliance',
      'intro_compliance_bullet_1':
          'Conformidad con leyes, normas y estándares de seguridad.',
      'intro_compliance_bullet_2':
          'Convierte las exigencias regulatorias en criterios claros de evaluación y decisión.',
      'intro_control_title': 'Control',
      'intro_control_bullet_1':
          'Control sobre infraestructura, accesos, datos y claves.',
      'intro_control_bullet_2':
          'Refuerza la autoridad operativa, la protección de activos críticos y la autonomía tecnológica.',
      'intro_continuity_title': 'Continuity',
      'intro_continuity_bullet_1':
          'Capacidad de resistir, responder y recuperarse.',
      'intro_continuity_bullet_2':
          'Fortalece la continuidad del negocio frente a fallas, crisis y eventos externos.',
      'intro_about_card_title': 'Sobre SoftwareOne',
      'intro_about_card_body':
          'SoftwareOne es una empresa global de soluciones tecnológicas, con actuación en modernización digital, nube, datos, seguridad y gobernanza. Con profundo conocimiento técnico, experiencia práctica en entornos regulados y reconocimiento como AWS Premier Partner, la empresa entrega proyectos con altos estándares de calidad, seguridad y consistencia operativa.',
      'intro_assessment_card_title':
          'Assessment de Madurez en Soberanía Digital',
      'intro_assessment_card_body':
          'El Assessment de Madurez en Soberanía Digital evalúa, de forma estructurada, el nivel de control, conformidad, resiliencia e independencia digital de la organización. Con criterios objetivos, medibles y auditables, la evaluación muestra el escenario actual, identifica brechas y apoya la definición de una hoja de ruta pragmática alineada con las exigencias del negocio y la regulación.',
      'intro_what_title': '📋 Qué es',
      'intro_what_body':
          'El Assessment de Madurez en Soberanía Digital de SoftwareOne evalúa de forma estructurada el nivel de control, cumplimiento, resiliencia e independencia digital de la organización. La evaluación considera aspectos técnicos, operativos, organizacionales y regulatorios, ofreciendo una visión clara del estado actual, de las brechas existentes y de las prioridades de evolución. El assessment se basa en criterios objetivos, medibles y auditables, lo que permite clasificar la madurez y apoyar la definición de un roadmap pragmático alineado con las exigencias del negocio y de la regulación.',
      'intro_about_title': '🏢 Sobre SoftwareOne',
      'intro_about_body':
          'SoftwareOne es una empresa global de soluciones en tecnología, con sede en Suiza y operación en Brasil, que apoya a las organizaciones en su jornada de modernización y transformación digital. Actuamos como socios estratégicos de nuestros clientes, combinando profundo conocimiento técnico, experiencia en entornos de nube, datos y seguridad, y un entendimiento práctico de los requisitos regulatorios locales y globales. Como AWS Premier Partner, SoftwareOne forma parte del nivel más alto de asociación con AWS, reconocida por su excelencia técnica comprobada, histórico consistente de proyectos exitosos y equipos altamente certificados, lo que demuestra nuestra capacidad para diseñar, implementar y operar entornos complejos y críticos en la nube con estrictos estándares de calidad, seguridad y gobernanza.',
      'intro_partnership_title':
          'Alianza SoftwareOne y AWS en Soberanía Digital',
      'intro_partnership_body':
          'SoftwareOne es socio estratégico de AWS para el tema de Soberanía Digital, siendo la única empresa en Brasil y una de las pocas en el mundo con esta competencia reconocida. Esta alianza une un profundo conocimiento técnico en entornos de nube con expertise en los requisitos regulatorios locales y globales, permitiendo apoyar a las organizaciones en la construcción de estrategias de soberanía digital alineadas con las demandas del negocio, los requisitos legales y los desafíos operativos de entornos digitales modernos y distribuidos.',
      'intro_sov_title': 'Soberanía Digital',
      'intro_sov_body':
          'La Soberanía Digital es la capacidad de una organización para mantener control, autoridad y visibilidad sobre sus datos, infraestructura y operaciones digitales, garantizando cumplimiento regulatorio, seguridad, resiliencia operativa, transparencia e independencia tecnológica. En entornos de nube, la soberanía digital permite atender a requisitos regulatorios y geopolíticos cada vez mayores sin sacrificar agilidad, innovación o escala, creando una base sostenible para la innovación segura y el crecimiento continuo.',
      'intro_challenges_title': '⚠️ Principales desafíos',
      'intro_challenge_1':
          'Cumplimiento simultáneo con múltiples leyes y regulaciones nacionales e internacionales.',
      'intro_challenge_2':
          'Garantizar la residencia, movimiento y control de datos en entornos distribuidos.',
      'intro_challenge_3':
          'Restricción y gobernanza de accesos operativos, incluidos operadores internos y terceros.',
      'intro_challenge_4':
          'Falta de visibilidad continua y evidencias auditables de cumplimiento.',
      'intro_challenge_5':
          'Necesidad de resiliencia y continuidad operativa frente a incidentes, fallos sistémicos o eventos geopolíticos.',
      'intro_challenge_6':
          'Escasez de competencias especializadas para diseñar, operar y evolucionar entornos soberanos.',
      'intro_benefits_title': '✅ Principales beneficios',
      'intro_benefit_1':
          'Reducción de riesgos regulatorios, operativos y reputacionales.',
      'intro_benefit_2':
          'Mayor transparencia y auditabilidad de los entornos digitales.',
      'intro_benefit_3':
          'Control efectivo sobre datos, infraestructura y operaciones críticas.',
      'intro_benefit_4':
          'Continuidad y resiliencia del negocio incluso en escenarios extremos.',
      'intro_benefit_5':
          'Mayor confianza de clientes, socios y organismos reguladores.',
      'intro_benefit_6':
          'Base sólida para la innovación segura, incluyendo datos sensibles y cargas de trabajo críticas.',
      'btn_start_assessment': 'Iniciar Assessment',
      'phases_title': 'Pilares de Soberanía Digital',
      'phases_choose': 'Elija un pilar para responder',
      'phase_compliance_label': 'Compliance',
      'phase_compliance_subtitle': 'Conformidad y requisitos regulatorios',
      'phase_continuity_label': 'Continuity',
      'phase_continuity_subtitle': 'Continuidad del negocio y resiliencia',
      'phase_control_label': 'Control',
      'phase_control_subtitle': 'Controles y gobernanza',
      'results_title': 'Resultados',
      'results_score_by_pillar': 'Puntuación por Pilar',
      'results_score_by_domain': 'Puntuación por Dominio',
      'results_no_data': 'No hay datos disponibles.',
      'results_overview_loading': 'El bot está analizando los resultados...',
      'results_retry': 'Intentar de nuevo',
      'results_radar_empty': 'Sin datos para radar',
      'results_generated_at': 'Generado en',
      'results_view_scores': 'Ver sus gráficos de puntuación',
      'results_available_hint':
          'Responda todas las preguntas de todas las fases para ver los resultados.',
      'results_new_generated': '¡Nuevo resultado generado!',
      'phases_obs':
          'Nota: los valores de los pilares (Compliance, Continuity, Control) deben corresponder al campo "pilar" de las preguntas en Xano.',
      'results_provided_by': 'Proporcionado por',
      'domain_continuity_portability': 'Continuidad y Portabilidad',
      'domain_governance_compliance': 'Gobernanza y Cumplimiento',
      'domain_operational_sovereignty': 'Soberanía Operacional',
      'domain_organizational_sovereignty': 'Soberanía Organizacional',
      'domain_data_sovereignty': 'Soberanía de Datos',
      'domain_infrastructure_sovereignty': 'Soberanía de Infraestructura',
      'back_to_pillars': 'Volver a pilares',
      'go_to_intro': 'Ir a introducción',
      'lang_pt': 'Português',
      'lang_en': 'English',
      'lang_es': 'Español',
      'login_title': 'Acceso',
      'login_card_title': 'Accede a tu cuenta',
      'login_welcome_title': 'Bienvenido',
      'login_subtitle': 'Ingresa tus datos para continuar.',
      'login_email_label': 'Correo electrónico',
      'login_email_required': 'Ingrese su correo electrónico',
      'login_email_invalid': 'Correo electrónico inválido',
      'login_password_label': 'Contraseña',
      'login_password_required': 'Ingrese su contraseña',
      'login_tip_config_xano': 'Consejo: configure la URL de Xano en lib/config.dart',
      'login_forgot_password': 'Olvidé mi contraseña',
      'login_forgot_success':
          'Si este correo está registrado, recibirá instrucciones para restablecer su contraseña.',
      'signup_title': 'Registrarse',
      'signup_heading': 'Crear cuenta',
      'signup_subtitle': '¡Vamos a empezar! Cree su cuenta en pocos pasos.',
      'signup_name_label': 'Nombre',
      'signup_name_hint': 'Su nombre',
      'signup_name_required': 'Ingrese su nombre',
      'signup_lastname_label': 'Apellido',
      'signup_lastname_hint': 'Su apellido',
      'signup_lastname_required': 'Ingrese su apellido',
      'signup_email_label': 'Correo electrónico',
      'signup_email_hint': 'usted@email.com',
      'signup_email_required': 'Ingrese su correo electrónico',
      'signup_email_invalid': 'Correo electrónico inválido',
      'signup_phone_label': 'Teléfono',
      'signup_phone_hint': '(11) 99999-9999',
      'signup_phone_required': 'Ingrese su teléfono',
      'signup_phone_invalid': 'El teléfono debe tener 10 u 11 dígitos (con código de área)',
      'signup_company_label': 'Empresa',
      'signup_company_hint': 'Nombre de su empresa',
      'signup_company_required': 'Ingrese la empresa',
      'signup_role_label': 'Cargo',
      'signup_role_hint': 'Ej: Gerente, Analista',
      'signup_password_label': 'Elija una contraseña',
      'signup_password_required': 'Ingrese una contraseña',
      'signup_password_too_short': 'La contraseña debe tener al menos 6 caracteres',
      'btn_register': 'Crear mi cuenta',
      'signup_already_have': '¿Ya tiene cuenta? ',
      'no_account': '¿No tiene cuenta? Regístrese',
      'right_panel_title': 'Lo que ofrecemos',
      'right_panel_intro':
          'En la plataforma de Soberanía Digital de SoftwareOne + AWS, usted puede:',
      'right_panel_topics':
          'Evaluar la madurez digital en los pilares Compliance, Control y Continuity.\n\n'
          'Completar un assessment guiado por fases, con progreso guardado.\n\n'
          'Visualizar puntuaciones por pilar y por dominio con gráficos.\n\n'
          'Recibir análisis automatizado del bot con recomendaciones prácticas.\n\n'
          'Identificar brechas, riesgos y prioridades de evolución.\n\n'
          'Apoyar la construcción de una hoja de ruta alineada con el negocio y la regulación.',
    },
  };

  String t(String key) {
    final langMap = _data[_lang] ?? _data[_fallback]!;
    return langMap[key] ?? _data[_fallback]![key] ?? key;
  }

  static AppLocalizations of(BuildContext context) {
    final scope = LocaleScope.of(context);
    final locale = scope?.locale ?? const Locale('pt');
    return AppLocalizations._(locale);
  }
}

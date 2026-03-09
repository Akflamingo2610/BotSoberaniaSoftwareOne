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
      'welcome_title': 'Bem-vindo ao Assessment de Maturidade em soberania digital da SoftwareOne com a AWS',
      'btn_login': 'Entrar',
      'btn_signup': 'Cadastre-se',
      'btn_logout': 'Sair',
      'intro_title': 'Entenda o Assessment',
      'intro_subtitle': 'Assessment de Maturidade',
      'intro_before_start': 'Antes de começar',
      'intro_desc': 'Entenda mais sobre a SoftwareOne e o Assessment de Maturidade em Soberania Digital.',
      'intro_time': 'Tempo estimado: 5–10 min',
      'intro_what_title': '📋 O que é',
      'intro_what_body':
          'O Assessment de Maturidade em Soberania Digital da SoftwareOne avalia de forma estruturada o nível de controle, conformidade, resiliência e independência digital da organização. A avaliação considera aspectos técnicos, operacionais, organizacionais e regulatórios, fornecendo uma visão clara do estado atual, das lacunas existentes e das prioridades de evolução. O assessment é baseado em critérios objetivos, mensuráveis e auditáveis, permitindo classificar a maturidade e apoiar a definição de um roadmap pragmático e alinhado às exigências do negócio e da regulação.',
      'intro_about_title': '🏢 Sobre a SoftwareOne',
      'intro_about_body':
          'A SoftwareOne é uma empresa global de soluções em tecnologia, com sede na Suíça e operação no Brasil, apoiando organizações em sua jornada de modernização e transformação digital. Atuamos como parceiros estratégicos de nossos clientes, combinando profundo conhecimento técnico, experiência em ambientes de nuvem, dados e segurança, e entendimento prático das exigências regulatórias locais e globais. Como AWS Premier Partner, a SoftwareOne integra o mais alto nível de parceria da AWS, reconhecido por excelência técnica comprovada, histórico consistente de entregas bem-sucedidas e equipes altamente certificadas, o que atesta nossa capacidade de projetar, implementar e operar ambientes complexos e críticos na nuvem com padrões rigorosos de qualidade, segurança e governança.',
      'intro_partnership_title':
          '🤝 Parceria SoftwareOne e AWS em Soberania Digital',
      'intro_partnership_body':
          'A SoftwareOne é parceira estratégica da AWS para o tema de Soberania Digital, sendo a única empresa no Brasil e uma das poucas no mundo com essa competência reconhecida. Essa parceria une profundo conhecimento técnico em ambientes de nuvem com expertise nas exigências regulatórias locais e globais, permitindo apoiar organizações na construção de estratégias de soberania digital alinhadas às demandas de negócio, aos requisitos legais e aos desafios operacionais de ambientes digitais modernos e distribuídos.',
      'intro_sov_title': '⚙️ Soberania Digital',
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
      'results_title': 'Resultados',
      'results_provided_by': 'Fornecidos por',
      'back_to_pillars': 'Voltar para pilares',
      'go_to_intro': 'Ir para introdução',
      'lang_pt': 'Português',
      'lang_en': 'English',
      'lang_es': 'Español',
      'login_title': 'Acesso',
      'login_subtitle': 'Use seu e-mail e senha para entrar.',
      'login_email_label': 'E-mail',
      'login_email_required': 'Informe seu e-mail',
      'login_email_invalid': 'E-mail inválido',
      'login_password_label': 'Senha',
      'login_password_required': 'Informe sua senha',
      'login_tip_config_xano': 'Dica: configure a URL do Xano em lib/config.dart',
      'signup_title': 'Cadastre-se',
      'signup_heading': 'Criar conta',
      'signup_subtitle': 'Preencha os dados para se cadastrar.',
      'signup_name_label': 'Nome',
      'signup_name_hint': 'Seu nome',
      'signup_name_required': 'Informe seu nome',
      'signup_lastname_label': 'Sobrenome',
      'signup_lastname_hint': 'Seu sobrenome',
      'signup_lastname_required': 'Informe seu sobrenome',
      'signup_email_label': 'E-mail',
      'signup_email_hint': 'seu@email.com',
      'signup_email_required': 'Informe seu e-mail',
      'signup_email_invalid': 'E-mail inválido',
      'signup_phone_label': 'Telefone',
      'signup_phone_hint': '(11) 99999-9999',
      'signup_phone_required': 'Informe seu telefone',
      'signup_phone_invalid': 'Telefone deve ter 10 ou 11 dígitos (com DDD)',
      'signup_company_label': 'Nome da empresa',
      'signup_company_hint': 'Nome da sua empresa',
      'signup_company_required': 'Informe o nome da empresa',
      'signup_role_label': 'Cargo na empresa',
      'signup_role_hint': 'Ex: Gerente, Analista',
      'signup_password_label': 'Senha',
      'signup_password_required': 'Informe uma senha',
      'signup_password_too_short': 'Senha deve ter no mínimo 6 caracteres',
      'btn_register': 'Cadastrar',
      'signup_already_have': 'Já tem conta? ',
      'no_account': 'Não tem uma conta ainda? Cadastre-se',
    },
    'en': {
      'app_title': 'Digital Sovereignty',
      'welcome_title': 'Welcome to the Software One and AWS Digital Sovereignty Maturity Assessment',
      'btn_login': 'Log in',
      'btn_signup': 'Sign up',
      'btn_logout': 'Log out',
      'intro_title': 'Understand the Assessment',
      'intro_subtitle': 'Maturity Assessment',
      'intro_before_start': 'Before you start',
      'intro_desc': 'Learn more about SoftwareOne and the Digital Sovereignty Maturity Assessment.',
      'intro_time': 'Estimated time: 5–10 min',
      'intro_what_title': '📋 What it is',
      'intro_what_body':
          'The Digital Sovereignty Maturity Assessment from SoftwareOne provides a structured view of your level of control, compliance, resilience, and digital independence. It considers technical, operational, organizational, and regulatory aspects to give a clear picture of the current state, existing gaps, and evolution priorities. The assessment is based on objective, measurable, and auditable criteria, helping classify maturity and define a pragmatic roadmap aligned with business and regulatory requirements.',
      'intro_about_title': '🏢 About SoftwareOne',
      'intro_about_body':
          'SoftwareOne is a global technology solutions company headquartered in Switzerland with operations in Brazil, supporting organizations in their journey of modernization and digital transformation. We act as a strategic partner to our customers by combining deep technical expertise, experience in cloud, data, and security, and practical understanding of local and global regulatory requirements. As an AWS Premier Partner, SoftwareOne is part of the highest partnership level with AWS, recognized for proven technical excellence, a consistent track record of successful deliveries, and highly certified teams, demonstrating our ability to design, implement, and operate complex and mission-critical cloud environments with strict quality, security, and governance standards.',
      'intro_partnership_title':
          '🤝 SoftwareOne and AWS partnership on Digital Sovereignty',
      'intro_partnership_body':
          'SoftwareOne is a strategic AWS partner for Digital Sovereignty and is the only company in Brazil, and one of the few worldwide, with this recognized competency. This partnership combines deep technical knowledge of cloud environments with expertise in local and global regulatory requirements, enabling organizations to build digital sovereignty strategies that are aligned with business demands, legal obligations, and the operational challenges of modern, distributed digital environments.',
      'intro_sov_title': '⚙️ Digital Sovereignty',
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
      'results_title': 'Results',
      'results_provided_by': 'Provided by',
      'back_to_pillars': 'Back to pillars',
      'go_to_intro': 'Go to introduction',
      'lang_pt': 'Português',
      'lang_en': 'English',
      'lang_es': 'Español',
      'login_title': 'Log in',
      'login_subtitle': 'Use your email and password to log in.',
      'login_email_label': 'Email',
      'login_email_required': 'Enter your email',
      'login_email_invalid': 'Invalid email',
      'login_password_label': 'Password',
      'login_password_required': 'Enter your password',
      'login_tip_config_xano': 'Tip: configure the Xano URL in lib/config.dart',
      'signup_title': 'Sign up',
      'signup_heading': 'Create account',
      'signup_subtitle': 'Fill in the information to sign up.',
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
      'signup_company_label': 'Company name',
      'signup_company_hint': 'Your company name',
      'signup_company_required': 'Enter the company name',
      'signup_role_label': 'Role in the company',
      'signup_role_hint': 'e.g. Manager, Analyst',
      'signup_password_label': 'Password',
      'signup_password_required': 'Enter a password',
      'signup_password_too_short': 'Password must be at least 6 characters',
      'btn_register': 'Register',
      'signup_already_have': 'Already have an account? ',
      'no_account': "Don't have an account yet? Sign up",
    },
    'es': {
      'app_title': 'Soberanía Digital',
      'welcome_title': 'Bienvenido al Assessment de Madurez en soberanía digital de Software One con AWS',
      'btn_login': 'Entrar',
      'btn_signup': 'Registrarse',
      'btn_logout': 'Salir',
      'intro_title': 'Entienda el Assessment',
      'intro_subtitle': 'Assessment de Madurez',
      'intro_before_start': 'Antes de comenzar',
      'intro_desc': 'Conozca más sobre SoftwareOne y el Assessment de Madurez en Soberanía Digital.',
      'intro_time': 'Tiempo estimado: 5–10 min',
      'intro_what_title': '📋 Qué es',
      'intro_what_body':
          'El Assessment de Madurez en Soberanía Digital de SoftwareOne evalúa de forma estructurada el nivel de control, cumplimiento, resiliencia e independencia digital de la organización. La evaluación considera aspectos técnicos, operativos, organizacionales y regulatorios, ofreciendo una visión clara del estado actual, de las brechas existentes y de las prioridades de evolución. El assessment se basa en criterios objetivos, medibles y auditables, lo que permite clasificar la madurez y apoyar la definición de un roadmap pragmático alineado con las exigencias del negocio y de la regulación.',
      'intro_about_title': '🏢 Sobre SoftwareOne',
      'intro_about_body':
          'SoftwareOne es una empresa global de soluciones en tecnología, con sede en Suiza y operación en Brasil, que apoya a las organizaciones en su jornada de modernización y transformación digital. Actuamos como socios estratégicos de nuestros clientes, combinando profundo conocimiento técnico, experiencia en entornos de nube, datos y seguridad, y un entendimiento práctico de los requisitos regulatorios locales y globales. Como AWS Premier Partner, SoftwareOne forma parte del nivel más alto de asociación con AWS, reconocida por su excelencia técnica comprobada, histórico consistente de proyectos exitosos y equipos altamente certificados, lo que demuestra nuestra capacidad para diseñar, implementar y operar entornos complejos y críticos en la nube con estrictos estándares de calidad, seguridad y gobernanza.',
      'intro_partnership_title':
          '🤝 Alianza SoftwareOne y AWS en Soberanía Digital',
      'intro_partnership_body':
          'SoftwareOne es socio estratégico de AWS para el tema de Soberanía Digital, siendo la única empresa en Brasil y una de las pocas en el mundo con esta competencia reconocida. Esta alianza une un profundo conocimiento técnico en entornos de nube con expertise en los requisitos regulatorios locales y globales, permitiendo apoyar a las organizaciones en la construcción de estrategias de soberanía digital alineadas con las demandas del negocio, los requisitos legales y los desafíos operativos de entornos digitales modernos y distribuidos.',
      'intro_sov_title': '⚙️ Soberanía Digital',
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
      'results_title': 'Resultados',
      'results_provided_by': 'Proporcionado por',
      'back_to_pillars': 'Volver a pilares',
      'go_to_intro': 'Ir a introducción',
      'lang_pt': 'Português',
      'lang_en': 'English',
      'lang_es': 'Español',
      'login_title': 'Acceso',
      'login_subtitle': 'Use su correo y contraseña para iniciar sesión.',
      'login_email_label': 'Correo electrónico',
      'login_email_required': 'Ingrese su correo electrónico',
      'login_email_invalid': 'Correo electrónico inválido',
      'login_password_label': 'Contraseña',
      'login_password_required': 'Ingrese su contraseña',
      'login_tip_config_xano': 'Consejo: configure la URL de Xano en lib/config.dart',
      'signup_title': 'Registrarse',
      'signup_heading': 'Crear cuenta',
      'signup_subtitle': 'Complete los datos para registrarse.',
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
      'signup_company_label': 'Nombre de la empresa',
      'signup_company_hint': 'Nombre de su empresa',
      'signup_company_required': 'Ingrese el nombre de la empresa',
      'signup_role_label': 'Función en la empresa',
      'signup_role_hint': 'Ej: Gerente, Analista',
      'signup_password_label': 'Contraseña',
      'signup_password_required': 'Ingrese una contraseña',
      'signup_password_too_short': 'La contraseña debe tener al menos 6 caracteres',
      'btn_register': 'Registrar',
      'signup_already_have': '¿Ya tiene cuenta? ',
      'no_account': '¿No tiene cuenta? Regístrese',
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

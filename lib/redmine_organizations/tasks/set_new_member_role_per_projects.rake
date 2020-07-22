namespace :redmine do
  namespace :organizations do

    desc "Set new member roles per projects"
    task :set_new_member_role_per_projects => [:environment] do

      # org = Organization.find(382) # PROD
      org = Organization.find(704) # PNM6
      puts "** Mise à jour pour l'organisation #{org} **"

      projects = org.self_and_descendants.map{|org|org.projects}.flatten.uniq.compact.select(&:active?)
      puts "Nombre de projets concernés : #{projects.size}"

      project_member = Role.find(4)
      gestionnaire = Role.find(23)
      mco = Function.find(18)
      puts "Nouveaux rôles ajoutés : #{gestionnaire} / #{mco}"

      # user_id : 847 # Vincent ROBERT
      users = [18, 1163] # Anthony Meauzoone, Miguel De Castro
      users.each do |user_id|
        user = User.find(user_id)
        puts "Utilisateur : #{user}"
        projects.each do |p|
          member = user.membership(p)
          if member.blank?
            member = Member.new(user: user, project: p)
            member.roles << project_member
            if member.save
              puts "Ajouté au projet : #{p}"
            else
              puts "! #{member.errors.messages} | #{p.identifier}"
            end
          end
          member.roles << gestionnaire
          member.functions << mco
          member.save
        end
      end

    end

  end
end

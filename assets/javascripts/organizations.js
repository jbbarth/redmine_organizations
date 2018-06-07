/* Organizations plugin javascripts */
function toggleOrgaForms(id, type) {
    var orga_id = "#" + type + "-" + id;
    var $texts = $(orga_id + "-roles," + orga_id + "-members");
    //=> doesn't work with forms, don't know why ... :/
    $texts.toggle(0, function () {
        var $forms = $(orga_id + "-roles-form," + orga_id + "-members-form");
        if ($texts.is(":visible")) {
            $forms.hide()
        }
        else {
            $forms.show()
        }
    })
}

//initialize big <selects> with jQuery.select2 if available
function initOrgasSelect2() {
    var $select = $(".orga-select2")
    if ($select.select2) {
        $select.select2({
            containerCss: {width: '100%', minWidth: '300px'},
            formatNoMatches: function (term) {
                return $('#label-no-data').html()
            }
        });
    }
}

//filter organizations on organizations/index page
//TODO: merge it with the one in redmine_better_crossprojects plugin
$(function () {
    //use jQuery.select2 if available
    initOrgasSelect2()
    //focus on search field on load
    $("#filter-by-org-name").focus()
    //filter projects depending on input value
    $("body").on("keyup", "#filter-by-org-name", function () {
        var needle = $.trim($(this).val().toLowerCase())
        var count = 0
        // Index page
        $(this).closest("table").find("td.name").each(function () {
            var name = $(this).data('filterValue').toLowerCase()
            var $elem = $(this).closest('tr')
            if (name.indexOf(needle) >= 0) {
                $elem.show()
                //restablish even/odd alternance
                $elem.removeClass("even")
                $elem.removeClass("odd")
                $elem.addClass(["odd", "even"][count % 2])
                count++
            } else {
                $elem.hide()
            }
        })
    })

    $("body").on("change", "#organizations_ids", function () {
        let organization_ids = $("#organizations_ids").select2('data').map(
            function (element) {
                return element.id;
            })
        let project_id = $("input#membership_project_id").val()
        $.ajax({
            url: '/organizations/autocomplete_users',
            type: 'get',
            data: {organization_ids: organization_ids, project_id: project_id},
            // success: function(data){ if(targetId) $('#'+targetId).html(data); },
            beforeSend: function () {
                $("#users_for_new_member").addClass('ajax-loading')
            },
            complete: function () {
                $("#users_for_new_member").removeClass('ajax-loading')
            }
        });
    })

    $("body").on("click", "form#new_membership #link_select_all", function (event) {
        event.preventDefault();
        $("#users_for_new_member input:checkbox[name='membership[user_ids][]']").each(function () {
            $(this).prop("checked", "checked");
        });
    })
    $("body").on("click", "form#new_membership #link_select_none", function (event) {
        event.preventDefault();
        $("#users_for_new_member input:checkbox[name='membership[user_ids][]']").each(function () {
            $(this).prop("checked", false);
        });
    })
})
